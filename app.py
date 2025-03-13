from fastapi import FastAPI, HTTPException, Depends
from pydantic import BaseModel
import asyncio
from graphlib import TopologicalSorter
from typing import Callable, List, Dict, Union
from dataclasses import dataclass

app = FastAPI()

# Pydantic models for request and response
class ProcessRequest(BaseModel):
    value: int

class TaskResult(BaseModel):
    operation: str
    result: int

class TaskError(BaseModel):
    error_code: int
    error_message: str

# For the response, each task maps to either a TaskResult or TaskError.
class ProcessResponse(BaseModel):
    results: Dict[str, Union[TaskResult, TaskError]]

# Task representation with dependencies
@dataclass
class Task:
    name: str
    func: Callable[..., asyncio.Future]
    dependencies: List[str] = None

    def __post_init__(self):
        if self.dependencies is None:
            self.dependencies = []

# Example asynchronous processing functions.
# process_double will simulate an error if value is negative.
async def process_double(value: int) -> TaskResult:
    await asyncio.sleep(1)  # Simulate async work
    if value < 0:
        raise ValueError("Value cannot be negative for doubling")
    return TaskResult(operation="double", result=value * 2)

async def process_square(value: int) -> TaskResult:
    await asyncio.sleep(1)
    return TaskResult(operation="square", result=value ** 2)

async def process_increment(value: int) -> TaskResult:
    await asyncio.sleep(1)
    return TaskResult(operation="increment", result=value + 1)

# Define tasks with dependencies:
# For example, process_square depends on process_double.
tasks = [
    Task(name="process_double", func=process_double),
    Task(name="process_square", func=process_square, dependencies=["process_double"]),
    Task(name="process_increment", func=process_increment),
]

async def run_tasks_concurrently(tasks: List[Task], value: int) -> Dict[str, Union[TaskResult, TaskError]]:
    """
    Build a dependency graph and run tasks in batches.
    - Tasks whose dependencies have failed are skipped and marked with a TaskError.
    - If a task fails during execution, its exception is caught and transformed into a TaskError.
    """
    # Build dependency graph: task name -> set of dependency names.
    graph = {task.name: set(task.dependencies) for task in tasks}
    try:
        ts = TopologicalSorter(graph)
        ts.prepare()  # Raises an error if a cycle exists.
    except Exception as e:
        raise ValueError("Dependency graph contains a cycle or error") from e

    results: Dict[str, Union[TaskResult, TaskError]] = {}
    while ts.is_active():
        ready = list(ts.get_ready())
        tasks_to_run = []
        tasks_to_skip = []
        for task_name in ready:
            task_obj = next(task for task in tasks if task.name == task_name)
            # Check if any dependency failed.
            failed_deps = [dep for dep in task_obj.dependencies if isinstance(results.get(dep), TaskError)]
            if failed_deps:
                tasks_to_skip.append(task_obj)
            else:
                tasks_to_run.append(task_obj)

        # Mark tasks that must be skipped due to dependency failure.
        for task_obj in tasks_to_skip:
            failed_deps = [dep for dep in task_obj.dependencies if isinstance(results.get(dep), TaskError)]
            results[task_obj.name] = TaskError(
                error_code=424,
                error_message=f"Dependency failure in: {', '.join(failed_deps)}"
            )
            ts.done(task_obj.name)

        # Run eligible tasks concurrently.
        if tasks_to_run:
            coroutines = [task_obj.func(value) for task_obj in tasks_to_run]
            batch_results = await asyncio.gather(*coroutines, return_exceptions=True)
            for task_obj, res in zip(tasks_to_run, batch_results):
                if isinstance(res, Exception):
                    results[task_obj.name] = TaskError(error_code=500, error_message=str(res))
                else:
                    results[task_obj.name] = res
                ts.done(task_obj.name)
    return results

# POST endpoint: Expects JSON body validated by ProcessRequest.
@app.post("/process", response_model=ProcessResponse)
async def process_post_endpoint(request: ProcessRequest):
    try:
        results = await run_tasks_concurrently(tasks, request.value)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    return ProcessResponse(results=results)

# GET endpoint: Expects query parameters (converted to ProcessRequest via dependency injection).
@app.get("/process", response_model=ProcessResponse)
async def process_get_endpoint(request: ProcessRequest = Depends()):
    try:
        results = await run_tasks_concurrently(tasks, request.value)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    return ProcessResponse(results=results)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
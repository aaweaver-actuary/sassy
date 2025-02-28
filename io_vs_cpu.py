import time
import numpy as np

FILE_NAME = "large_numbers.npy"
FILE_SIZE = 1 * 1024 * 1024 * 1024  # 1 GB
NUMBERS_PER_LINE = 10
TOTAL_NUMBERS_IN_FILE = FILE_SIZE // 2  # Approximate number of numbers

def generate_binary_file(file_name: str = FILE_NAME, total_numbers: int = TOTAL_NUMBERS_IN_FILE):
    print(f"Generating binary file with {total_numbers} random numbers...", end="")
    numbers = np.random.randint(1, 1000, size=total_numbers, dtype=np.uint16)
    np.save(file_name, numbers)
    print("Done")

def io_operation(file_name: str = FILE_NAME) -> np.ndarray:
    print(f"IO Operation: Reading binary file {file_name}...", end="")
    start_time = time.time()
    data = np.load(file_name)
    io_time = time.time() - start_time
    print(f"Done in {io_time:.2f} seconds")
    return data, io_time

def cpu_operation(data: np.ndarray) -> float:
    print("CPU Operation: Calculating sum of numbers...", end="")
    start_time = time.time()
    total_sum = np.sum(data)
    cpu_time = time.time() - start_time
    print(f"Done in {cpu_time:.5f} seconds")
    return total_sum, cpu_time

def main():
    generate_binary_file()

    data, io_time = io_operation()
    _, cpu_time = cpu_operation(data)

    print(f"\nI/O Time: {io_time:.2f} seconds")
    print(f"CPU Time: {cpu_time:.5f} seconds")
    print(f"I/O is ~{io_time / cpu_time:.2f} times slower than CPU operations")

if __name__ == "__main__":
    main()

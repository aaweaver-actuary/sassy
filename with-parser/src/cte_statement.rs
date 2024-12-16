use std::str::FromStr;

pub const FINAL_CTE_STATEMENT_NAME: &str = "FINAL";

#[derive(Debug, PartialEq, Clone)]
pub struct CteStatement {
    pub name: String,
    pub statement: String,
}

impl CteStatement {
    pub fn new(name: &str, statement: &str) -> CteStatement {
        CteStatement {
            name: name.to_string(),
            statement: statement
                .to_string()
                .trim()
                .replace("\n", "")
                .replace("\t", "")
                .replace("  ", " ")
                .replace("  ", " ")
                .replace("  ", " "),
        }
    }

    pub fn final_statement(statement: &str) -> CteStatement {
        Self::new(FINAL_CTE_STATEMENT_NAME, statement)
    }
}

impl FromStr for CteStatement {
    type Err = String;

    fn from_str(raw: &str) -> Result<CteStatement, Self::Err> {
        let parts: Vec<&str> = raw.split(">").map(|s| s.trim()).collect();
        if parts.len() <= 1 {
            return Err(format!(
                "Invalid CTE statement. Expected a single name > expression pair, got {}",
                raw
            ));
        }
        let name = parts[0].trim();
        let statement = parts[1].trim();
        Ok(CteStatement::new(name, statement))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn can_create_cte_statement() {
        let cte = CteStatement::new("name", "statement");
        assert_eq!(cte.name, "name");
        assert_eq!(cte.statement, "statement");
    }

    #[test]
    fn can_create_cte_statement_from_str() {
        let cte = CteStatement::new("name", "statement");
        let cte_from_str = CteStatement::from_str("name > statement").unwrap();
        assert_eq!(cte, cte_from_str);
    }
}

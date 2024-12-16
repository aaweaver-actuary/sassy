use std::str::FromStr;

use crate::cte_statement::CteStatement;
use crate::raw_with_statement::RawWithStatement;

#[derive(Debug, Clone)]
pub struct TransformedWithStatement {
    pub raw_cte_statements: Vec<String>,
    pub cte_statements: Vec<CteStatement>,
}

impl FromStr for TransformedWithStatement {
    type Err = String;

    fn from_str(raw: &str) -> Result<TransformedWithStatement, Self::Err> {
        let new_raw = raw.trim();
        if !new_raw.contains(">") && new_raw.is_empty() {
            return Err("Empty string".to_string());
        }
        let rws = RawWithStatement::new(raw.to_string());
        let raw_cte_statements = rws.statements.clone();

        let cte_statements = raw_cte_statements
            .iter()
            .enumerate()
            .map(|(i, s)| {
                if (i + 1) == raw_cte_statements.len() {
                    Ok(CteStatement::final_statement(s))
                } else {
                    CteStatement::from_str(s)
                }
            })
            .collect::<Result<Vec<CteStatement>, String>>()?;

        Ok(TransformedWithStatement {
            raw_cte_statements,
            cte_statements,
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;


    #[test]
    fn can_get_transformed_with_statement_from_raw() {
        let raw = "string";
        let tws = TransformedWithStatement::from_str(raw);
        assert_eq!(tws.unwrap().raw_cte_statements, vec!["string".to_string()]);
    }

    #[test]
    fn test_raw_cte_representing_something_like_expected_input() {
        let raw = r#"
          ds1 > 
            select key, value1 from table1

            | ds2 > 
                select key, value2 from table2

            | ds3 >
                select key, value3 from table3

            | joined > 
                select 
                    ds1.key, 
                    ds1.value1, 
                    ds2.value2, 
                    ds3.value3
                
                from ds1
                join ds2 
                    on ds1.key = ds2.key
                join ds3 
                    on ds1.key = ds3.key

            | select * from joined
        "#
        .to_string();

        let tws = TransformedWithStatement::from_str(&raw);
        let actual_statements = tws
            .unwrap()
            .cte_statements
            .iter()
            .map(|s| CteStatement::new(&s.name, &s.statement))
            .collect::<Vec<CteStatement>>();

        let expected_statements = [
            CteStatement::new("ds1", "select key, value1 from table1"),
            CteStatement::new("ds2", "select key, value2 from table2"),
            CteStatement::new("ds3", "select key, value3 from table3"),
            CteStatement::new(
                "joined",
                r#"select 
ds1.key, 
ds1.value1, 
ds2.value2, 
ds3.value3 
from ds1 
join ds2  
on ds1.key = ds2.key 
join ds3 
on ds1.key = ds3.key "#
                .trim()
                .replace("\n", "")
                .replace("\t", "")
                .replace("  ", " ")
                .replace("  ", " ")
                .replace("  ", " ")
                .as_str(),
            ),
            CteStatement::final_statement("select * from joined"),
        ];

        actual_statements.iter().enumerate().for_each(|(i, s)| {
            let expected = &expected_statements[i];
            #[allow(clippy::needless_late_init)]
            let actual = s;

            assert_eq!(actual, expected);
        });
    }
}

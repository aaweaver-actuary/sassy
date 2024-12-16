#[derive(Debug, Clone)]
pub struct RawWithStatement {
    pub raw: String,
    pub statements: Vec<String>,
}

impl RawWithStatement {
    pub fn new(raw: String) -> Self {
        let statements = Self::parse_statements_from_raw(&raw);
        Self { raw, statements }
    }

    fn parse_statements_from_raw(raw: &str) -> Vec<String> {
        let mut statements = Vec::new();
        raw.split("|").for_each(|s| {
            statements.push(s.to_string());
        });
        statements
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn clean_string_for_test(s: &str) -> String {
        s.trim()
            .replace("\n", "")
            .replace("  ", "")
            .replace("\t", "")
    }

    #[test]
    fn test_raw_with_statement() {
        let raw = "a|b|c".to_string();
        let rws = RawWithStatement::new(raw);
        assert_eq!(rws.raw, "a|b|c");
        assert_eq!(
            rws.statements,
            vec!["a".to_string(), "b".to_string(), "c".to_string()]
        );
    }

    #[test]
    fn test_raw_with_no_delimiters() {
        let raw = "select * from tablename where a=345".to_string();
        let rws = RawWithStatement::new(raw);
        assert_eq!(rws.raw, "select * from tablename where a=345");
        assert_eq!(
            rws.statements,
            vec!["select * from tablename where a=345".to_string()]
        );
    }

    #[test]
    fn test_raw_cte_representing_something_like_expected_input_pipes_on_new_line() {
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
        let rws = RawWithStatement::new(raw);
        let expected_statements = [
            r#"
              ds1 > 
                select key, value1 from table1
            "#
            .to_string(),
            r#"
              ds2 > 
                select key, value2 from table2
            "#
            .to_string(),
            r#"
              ds3 >
                select key, value3 from table3
            "#
            .to_string(),
            r#"
              joined > 
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
            "#
            .to_string(),
            r#"
              select * from joined
            "#
            .to_string(),
        ];

        assert_eq!(
            clean_string_for_test(rws.raw.as_str()),
            clean_string_for_test(
                r#"
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
            )
        );

        rws.statements.iter().enumerate().for_each(|(i, s)| {
            let expected = clean_string_for_test(expected_statements.get(i).unwrap());
            let actual = clean_string_for_test(s);

            assert_eq!(actual, expected);
        });

        assert_eq!(rws.statements.len(), expected_statements.len());
    }


    #[test]
    fn test_raw_cte_representing_something_like_expected_input_pipe_on_prev_line() {
        let raw = r#"
          ds1 > 
            select key, value1 from table1 |

            ds2 > 
                select key, value2 from table2 |

            ds3 >
                select key, value3 from table3 |

            joined > 
                select 
                    ds1.key, 
                    ds1.value1, 
                    ds2.value2, 
                    ds3.value3
                
                from ds1
                join ds2 
                    on ds1.key = ds2.key
                join ds3 
                    on ds1.key = ds3.key |

            select * from joined
        "#
        .to_string();
        let rws = RawWithStatement::new(raw);
        let expected_statements = [
            r#"
              ds1 > 
                select key, value1 from table1
            "#
            .to_string(),
            r#"
              ds2 > 
                select key, value2 from table2
            "#
            .to_string(),
            r#"
              ds3 >
                select key, value3 from table3
            "#
            .to_string(),
            r#"
              joined > 
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
            "#
            .to_string(),
            r#"
              select * from joined
            "#
            .to_string(),
        ];

        assert_eq!(
            clean_string_for_test(rws.raw.as_str()),
            clean_string_for_test(
                r#"
                    ds1 > 
                        select key, value1 from table1 |

                        ds2 > 
                            select key, value2 from table2 |

                        ds3 >
                            select key, value3 from table3 |

                        joined > 
                            select 
                                ds1.key, 
                                ds1.value1, 
                                ds2.value2, 
                                ds3.value3
                            
                            from ds1
                            join ds2 
                                on ds1.key = ds2.key
                            join ds3 
                                on ds1.key = ds3.key |

                        select * from joined
                "#
            )
        );

        rws.statements.iter().enumerate().for_each(|(i, s)| {
            let expected = clean_string_for_test(expected_statements.get(i).unwrap());
            let actual = clean_string_for_test(s);

            assert_eq!(actual, expected);
        });

        assert_eq!(rws.statements.len(), expected_statements.len());
    }
}

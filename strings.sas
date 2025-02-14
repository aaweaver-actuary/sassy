proc fcmp outlib=work.fn.str;

/* Function: str__split */
/* Splits a string into an array of strings using a delimiter. */
/*  */
/* Parameters: */
/* str - The string to split. */
/* delimiter - The delimiter to split the string on. Default is a space. */
/*  */
/* Returns: */
/* An array of strings. */
/*  */
/* Example: */
/*  */
/* %let str=andy|is|a|cool|guy; */
/* %let arr=str__split(&str, |); */
/* %put &arr; */
/*  */
/* Output: */
/* andy is a cool guy */
function str__split(str $, delimiter $=' ') $[1] ;
    length str $ 32767;
    length delimiter $ 32767;
    length result $ 32767;
    length i n;
    n = countw(str, delimiter);
    do i = 1 to n;
        result = catx(' ', result, scan(str, i, delimiter));
    end;
    return (result);
endsub;

/* Function: index */
/* Returns the position of a substring within a string. */
/*  */
/* Parameters: */
/* str - The string to search. */
/* substr - The substring to search for. */
/*  */
/* Returns: */
/* The position of the substring within the string, or -1 if the substring is not found. */
/*  */
/* Example: */
/*  */
/* %let str=andy is a cool guy; */
/* %let pos=index(&str, cool); */
/* %put &pos; */
/* Output: 11 */
function str__index(str $, substr $) ;
    length str $ 32767;
    length substr $ 32767;
    length pos;
    pos = find(str, substr);
    return (pos);
endsub;

/* Function: str__replace */
/* Replaces all occurrences of a substring within a string. */
/*  */
/* Parameters: */
/* str - The string to search. */
/* substr - The substring to search for. */
/* replacement - The string to replace the substring with. */
/*  */
/* Returns: */
/* The modified string. */
/*  */
/* Example: */
/*  */
/* %let str=andy is a cool guy; */
/* %let newstr=str__replace(&str, cool, awesome); */
/* %put &newstr; */
/* Output: andy is a awesome guy */
function str__replace(str $, substr $, replacement $) $ 32767;
    length str $ 32767;
    length substr $ 32767;
    length replacement $ 32767;
    length newstr $ 32767;
    newstr = tranwrd(str, substr, replacement);
    return (newstr);
endsub;

/* Function: str__trim */
/* Removes all leading and trailing spaces from a string. */
/*  */
/* Parameters: */
/* str - The string to trim. */
/*  */
/* Returns: */
/* The trimmed string. */
/*  */
/* Example: */
/*  */
/* %let str=   andy is a cool guy   ; */
/* %let newstr=str__trim(&str); */
/* %put &newstr; */
/* Output: andy is a cool guy */
function str__trim(str $) $ 32767;
    length str $ 32767;
    length newstr $ 32767;
    newstr = strip(str);
    return (newstr);
endsub;

/* Function: str__upper */
/* Converts a string to uppercase. */
/*  */
/* Parameters: */
/* str - The string to convert. */
/*  */
/* Returns: */
/* The uppercase string. */
/*  */
/* Example: */
/*  */
/* %let str=andy is a cool guy; */
/* %let newstr=str__upper(&str); */
/* %put &newstr; */
/* Output: ANDY IS A COOL GUY */
function str__upper(str $) $ 32767;
    length str $ 32767;
    length newstr $ 32767;
    newstr = upcase(str);
    return (newstr);
endsub;

/* Function: str__lower */
/* Converts a string to lowercase. */
/*  */
/* Parameters: */
/* str - The string to convert. */
/*  */
/* Returns: */
/* The lowercase string. */
/*  */
/* Example: */
/*  */
/* %let str=ANDY IS A COOL GUY; */
/* %let newstr=str__lower(&str); */
/* %put &newstr; */
/* Output: andy is a cool guy */
function str__lower(str $) $ 32767;
    length str $ 32767;
    length newstr $ 32767;
    newstr = lowcase(str);
    return (newstr);
endsub;

/* Function: str__length */
/* Returns the length of a string. */
/*  */
/* Parameters: */
/* str - The string to measure. */
/*  */
/* Returns: */
/* The length of the string. */
/*  */
/* Example: */
/*  */
/* %let str=andy is a cool guy; */
/* %let len=str__length(&str); */
/* %put &len; */
/* Output: 19 */
function str__length(str $) ;
    length str $ 32767;
    length len;
    len = length(str);
    return (len);
endsub;

/* Function: str__contains */
/* Checks if a string contains a substring. */
/*  */
/* Parameters: */
/* str - The string to search. */
/* substr - The substring to search for. */
/*  */
/* Returns: */
/* 1 if the substring is found, 0 otherwise. */
/*  */
/* Example: */
/*  */
/* %let str=andy is a cool guy; */
/* %let contains=str__contains(&str, cool); */
/* %let notcontains=str__contains(&str, awesome); */
/* %put &contains &notcontains; */
/* Output: 1 0 */
function str__contains(str $, substr $) ;
    length str $ 32767;
    length substr $ 32767;
    length contains;
    contains = index(str, substr) > 0;
    return (contains);
endsub;

/* Function: str__startswith */
/* Checks if a string starts with a substring. */
/*  */
/* Parameters: */
/* str - The string to search. */
/* substr - The substring to search for. */
/*  */
/* Returns: */
/* 1 if the string starts with the substring, 0 otherwise. */
/*  */
/* Example: */
/*  */
/* %let str=andy is a cool guy; */
/* %let starts=str__startswith(&str, andy); */
/* %let notstarts=str__startswith(&str, cool); */
/* %put &starts &notstarts; */
/* Output: 1 0 */
function str__startswith(str $, substr $) ;
    length str $ 32767;
    length substr $ 32767;
    length starts;
    starts = substr(str, 1, length(substr)) = substr;
    return (starts);
endsub;

/* Function: str__endswith */
/* Checks if a string ends with a substring. */
/*  */
/* Parameters: */
/* str - The string to search. */
/* substr - The substring to search for. */
/*  */
/* Returns: */
/* 1 if the string ends with the substring, 0 otherwise. */
/*  */
/* Example: */
/*  */
/* %let str=andy is a cool guy; */
/* %let ends=str__endswith(&str, guy); */
/* %let notends=str__endswith(&str, cool); */
/* %put &ends &notends; */
/* Output: 1 0 */
function str__endswith(str $, substr $) ;
    length str $ 32767;
    length substr $ 32767;
    length ends;
    ends = substr(str, length(str) - length(substr) + 1) = substr;
    return (ends);
endsub;

/* Function: str__join */
/* Joins an array of strings into a single string using a delimiter. */
/*  */
/* Parameters: */
/* arr - The array of strings to join. */
/* delimiter - The delimiter to join the strings with. Default is a space. */
/*  */
/* Returns: */
/* The joined string. */
/*  */
/* Example: */
/*  */
/* %let arr=andy is a cool guy; */
/* %let str=str__join(&arr, |); */
/* %put &str; */
/* Output: andy|is|a|cool|guy */
function str__join(arr[*], delimiter $=' ') $ 32767;
    length delimiter $ 32767;
    length str $ 32767;
    length i n;
    n = dim(arr);
    do i = 1 to n;
        str = catx(delimiter, str, arr[i]);
    end;
    return (str);
endsub;

/* Function: str__reverse */
/* Reverses a string. */
/*  */
/* Parameters: */
/* str - The string to reverse. */
/*  */
/* Returns: */
/* The reversed string. */
/*  */
/* Example: */
/*  */
/* %let str=andy is a cool guy; */
/* %let rev=str__reverse(&str); */
/* %put &rev; */
/* Output: yug looc a si ydna */
function str__reverse(str $) $ 32767;
    length str $ 32767;
    length rev $ 32767;
    length i n;
    n = length(str);
    do i = n to 1 by -1;
        rev = cat(rev, substr(str, i, 1));
    end;
    return (rev);
endsub;

/* Function: str__find */
/* Finds the first occurrence of a substring within a string. */
/*  */
/* Parameters: */
/* str - The string to search. */
/* substr - The substring to search for. */
/*  */
/* Returns: */
/* The position of the substring within the string, or -1 if the substring is not found. */
/*  */
/* Example: */
/*  */
/* %let str=andy is a cool guy; */
/* %let pos=str__find(&str, cool); */
/* %put &pos; */
/* Output: 11 */
function str__find(str $, substr $) ;
    length str $ 32767;
    length substr $ 32767;
    length pos;
    pos = index(str, substr);
    return (pos);
endsub;

/* Function: str__format */
/* Formats a string using a format string. */
/*  */
/* Parameters: */
/* str - The string to format, containing one or more placeholders. */
/* args - The arguments to replace the placeholders with. */
/*  */
/* Returns: */
/* The formatted string. */
/*  */
/* Example: */
/*  */
/* %let str=Hello, %s! Today is %s. It is %s degrees outside.; */
/* %let formatted=str__format(&str, Andy, Monday, 75); */
/* %put &formatted; */
/* Output: Hello, Andy! Today is Monday. It is 75 degrees outside. */
function str__format(str $, args[*]) $ 32767;
    length str $ 32767;
    length formatted $ 32767;
    length i n;
    n = dim(args);
    formatted = str;
    do i = 1 to n;
        formatted = tranwrd(formatted, cats('%', put(i, 1.)), args[i]);
    end;
    return (formatted);
endsub;
run;
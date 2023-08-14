%{
#include "scanner.hh"
#include "parser.tab.hh"

#undef  YY_DECL
#define YY_DECL int IPL::Scanner::yylex( IPL::Parser::semantic_type * const lval, IPL::Parser::location_type *loc )

#define YY_USER_ACTION loc->step(); loc->columns(yyleng);

// token is a short hand for IPL::Parser::token


using token = IPL::Parser::token;

%}


/* %option debug */
%option nodefault
%option yyclass="Scanner"
%option noyywrap
%option c++

%%

%{ /** Code executed at the beginning of yylex **/

        yylval = lval;
        
%}

[ \t ]                             //skip
[\n]                    loc->lines();
\/\*.*\*\/               // multi line compound_statement  
"struct"                           {   
            yylval->emplace< std::string >( YYText() );
                return token::STRUCT;
}
"float"                           {   
            yylval->emplace< std::string >( YYText() );
                return token::FLOAT;
}
"int"                             {   
            yylval->emplace< std::string >( YYText() );
                return token::INT;
}
"void"                           {   
            yylval->emplace< std::string >( YYText() );
                return token::VOID;
}
"if"                             {   
            yylval->emplace< std::string >( YYText() );
                return token::IF;
}
"else"                           {   
            yylval->emplace< std::string >( YYText() );
                return token::ELSE;
}

"while"                          {   
            yylval->emplace< std::string >( YYText() );
                return token::WHILE;
}
"for"                            {   
            yylval->emplace< std::string >( YYText() );
                return token::FOR;
}
"return"                         {   
            yylval->emplace< std::string >( YYText() );
                return token::RETURN;
}
"||"                          {   
            yylval->emplace< std::string >( YYText() );
                return token::OR_OP;
}
"&&"                          {   
            yylval->emplace< std::string >( YYText() );
                return token::AND_OP;
}
"=="                          {   
            yylval->emplace< std::string >( YYText() );
                return token::EQ_OP;
}
"!="                          {   
            yylval->emplace< std::string >( YYText() );
                return token::NE_OP;
}
"<="                          {   
            yylval->emplace< std::string >( YYText() );
                return token::LE_OP;
}
">="                          {   
            yylval->emplace< std::string >( YYText() );
                return token::GE_OP;
}
(\+\+)+                          {
            yylval->emplace< std::string >( YYText() );
                return token::INC_OP;
}
"->"                          {   
            yylval->emplace< std::string >( YYText() );
                return token::PTR_OP;
}
[a-zA-Z_][a-zA-Z_0-9]*                  {
            yylval->emplace< std::string >( YYText() );
                return token::IDENTIFIER;
}
[1-9][0-9]*|0[bB][01]*|0[0-7]*|0[xX][0-9a-fA-F]* {
            yylval->emplace< std::string >( YYText() );
                return token::INT_CONSTANT;
}
([0-9]+\.[0-9]*|[0-9]*\.[0-9]+)([eE][+-]?[0-9]+)? {
            yylval->emplace< std::string >( YYText() );
                return token::FLOAT_CONSTANT;
}
["]([^"\\\n]|\\.|\\\n)*["]               {
            yylval->emplace< std::string >( YYText() );
                return token::STRING_LITERAL;
}
"{"                                         return '{';
"}"                                         return '}';
":"                                         return ':';
";"                                         return ';';
"("                                         return '(';
")"                                         return ')';
","                                         return ',';
"["                                         return '[';
"]"                                         return ']';
"*"                                         return '*';
"="                                         return '=';
"<"                                         return '<';
">"                                         return '>';
"+"                                         return '+';
"-"                                         return '-';
"/"                                         return '/';
"."                                         return '.';
"!"                                         return '!';
"&"                                         return '&';  
<<EOF>>         yyterminate();
.                                        ;
%%


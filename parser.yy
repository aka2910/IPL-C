%skeleton "lalr1.cc"
%require  "3.0.1"

%defines 
%define api.namespace {IPL}
%define api.parser.class {Parser}
%define api.location.type {IPL::location}

%define parse.trace

%code requires{
	#include "ast.hh"
	// #include "symtab.hh"
	#include "location.hh"

   namespace IPL {
      class Scanner;
   }

  // # ifndef YY_NULLPTR
  // #  if defined __cplusplus && 201103L <= __cplusplus
  // #   define YY_NULLPTR nullptr
  // #  else
  // #   define YY_NULLPTR 0
  // #  endif
  // # endif

}

%printer { std::cerr << $$; } STRUCT
%printer { std::cerr << $$; } FLOAT 
%printer { std::cerr << $$; } INT
%printer { std::cerr << $$; } PRINTF
%printer { std::cerr << $$; } MAIN
%printer { std::cerr << $$; } VOID
%printer { std::cerr << $$; } IF
%printer { std::cerr << $$; } ELSE
%printer { std::cerr << $$; } WHILE
%printer { std::cerr << $$; } FOR
%printer { std::cerr << $$; } RETURN
%printer { std::cerr << $$; } OR_OP
%printer { std::cerr << $$; } AND_OP
%printer { std::cerr << $$; } EQ_OP
%printer { std::cerr << $$; } NE_OP
%printer { std::cerr << $$; } LE_OP
%printer { std::cerr << $$; } GE_OP
%printer { std::cerr << $$; } INC_OP
%printer { std::cerr << $$; } PTR_OP
%printer { std::cerr << $$; } IDENTIFIER
%printer { std::cerr << $$; } INT_CONSTANT
%printer { std::cerr << $$; } FLOAT_CONSTANT
%printer { std::cerr << $$; } STRING_LITERAL

%parse-param { Scanner  &scanner  }
%locations
%code{
   #include <iostream>
   #include <cstdlib>
   #include <fstream>
   #include <string>
   #include <stack>
   #include <vector>
   
   #include "scanner.hh"
   #include "print.hh"
   int nodeCount = 0;
   using namespace std;
   symtab* gst = new symtab();

	stack <symtab*> table_stack; 
	string curr_func;
	stack <string> local_varlist;
	stack <vector<void*>*> local_exprn;
	stack <vector<string>*> local_type;
	std::map<string,int> glob_str;
	int curr_index=0;
	int jump_index=2;
	int arr_level=0;
	std::string curr_struct1;
	std::string curr_ident;
	std::map<string,abstract_astnode*> ast;
	std::string curr_struct;
	bool is_struct=true;
	stack <row*> func_list;
	bool is_pointer1(string s){
        if(s.find('*')==std::string::npos){
            if(s.find('[')==std::string::npos){
                return false;
            }
        }
        return true;
    }




#undef yylex
#define yylex IPL::Parser::scanner.yylex

}




%define api.value.type variant
%define parse.assert

%start translation_unit



%token '\n'
%token <std::string> STRUCT OTHERS
%token <std::string> FLOAT 
%token <std::string> INT
%token <std::string> PRINTF
%token <std::string> MAIN
%token <std::string> VOID
%token <std::string> IF
%token <std::string> ELSE
%token <std::string> WHILE
%token <std::string> FOR
%token <std::string> RETURN
%token <std::string> OR_OP
%token <std::string> AND_OP
%token <std::string> EQ_OP
%token <std::string> NE_OP
%token <std::string> LE_OP
%token <std::string> GE_OP
%token <std::string> INC_OP
%token <std::string> PTR_OP
%token <std::string> IDENTIFIER
%token <std::string> INT_CONSTANT
%token <std::string> FLOAT_CONSTANT
%token <std::string> STRING_LITERAL
%token '{' '}' ':' ';' '(' ')' ',' '[' ']' '*' '=' '<' '>' '+' '/' '.' '-' '!' '%' '&' 

%nterm <nterm_datatype> printf_call translation_unit struct_specifier function_definition type_specifier fun_declarator parameter_list parameter_declaration declarator_arr declarator compound_statement statement_list statement assignment_expression assignment_statement procedure_call expression logical_and_expression equality_expression relational_expression additive_expression unary_expression multiplicative_expression postfix_expression primary_expression expression_list unary_operator selection_statement iteration_statement declaration_list declaration declarator_list new_nonterm

%%

translation_unit:
	struct_specifier
		{	

		}
		|
	function_definition
		{

		}
		|
	translation_unit struct_specifier
		{

		}
		|
	translation_unit function_definition
		{


		}
		;
struct_specifier:
	STRUCT IDENTIFIER '{' 
	{
		row* r = new row();
		is_struct = true;
		r->name = $1 +" "+ $2;
		curr_struct = r->name;
		if(gst->st.find(r->name)!=gst->st.end()){
			error(@2,"The struct \""+r->name+"\" has a previous definition");
		}
		r->varfunc = "struct";
		r->global = "global";
		r->size = 0;
		r->offset = 0;
		r->type = "-";
		r->next = new symtab();
		r->next->curr_offset =0;
		gst->st[r->name] = r;
		table_stack.push(r->next);			
	}
	declaration_list '}' ';'
	{
		gst->st[$1+" "+$2]->size = $5.size;
		table_stack.pop();

	}		
	;
function_definition:
	type_specifier
	{
		is_struct = false;
		row* r = new row();
		r->name = "";
		r->varfunc = "fun";
		r->global = "global";
		r->size = 0;
		r->offset = 0;
		r->type = $1.name;
		r->next = new symtab();
		r->next->curr_offset=0;
		r->next->param_offset=8;
		gst->st[r->name]=r; 
		table_stack.push(r->next);
		func_list.push(r);


	}
	fun_declarator {
		row * r = gst->st[""];
		r->name=$3.name;
		if(gst->st.find(r->name)!=gst->st.end()){
			error(@2,"The function \""+r->name+"\" has a previous definition");
		}
		gst->st[r->name]=r;
		gst->st.erase("");
	}
	compound_statement
	{
		
		ast[$3.name] = $5.ast;
		func_list.pop();
	}
		;



type_specifier:
	VOID
		{
			$$.name="void";
			$$.size = 4;

		}
		|
	INT
		{
			$$.name="int";
			$$.size = 4;
		}
		|
	STRUCT IDENTIFIER
		{
			$$.name= $1+" "+$2;
			if(gst->st.find($$.name)==gst->st.end()){
				error(@1,"Struct "+$2+" is not defined");
			}
			$$.size = gst->st[$$.name]->size;

		}
		;
fun_declarator:
	IDENTIFIER '(' parameter_list ')'
		{
			$$.name = $1;
			symtab* local_symtab = table_stack.top();
			while(local_varlist.size()>0)
			{
				string s=local_varlist.top();
				local_varlist.pop();
				row * r = local_symtab->st[s];
				r->offset= local_symtab->param_offset;
				local_symtab->param_offset +=r->size;
			}
		}
		|
	IDENTIFIER '(' ')'
		{
			$$.name = $1;

		}
		;
parameter_list:
	parameter_declaration
		{

		}
		|
	parameter_list ',' parameter_declaration
		{

		}
		;
parameter_declaration:
	type_specifier declarator
		{
			$$.name = $2.name;
			symtab* local_symtab = table_stack.top();
			row * r = local_symtab->st[$$.name];
			r->global="param";
			bool is_pointer = false;
			if(r->type[0]=='*')is_pointer=true;
			r->type = $1.name+r->type;
			if(is_pointer){
				r->size = 4*r->size;
			}
			else r->size = $1.size*r->size;
			
			local_varlist.push($$.name);
			if($1.name=="void" && !is_pointer){
				error(@1,"Cannot declare parameter of type "+r->type);
			}
			

		}
		;
declarator_arr:
	IDENTIFIER
		{
			$$.name = $1;
			symtab* local_symtab = table_stack.top();
			row * r = new row();
			r->name = $1;
			r->varfunc= "var";
			r->global="local";
			r->size=1;
			r->offset=0; //dummy
			r->type = "";
			r->next = nullptr;
			if(local_symtab->st.find(r->name)!=local_symtab->st.end()){
				error(@1,"\""+$1+"\" has a previous declaration");
			}
			local_symtab->st[r->name]=r;
		}
		|
	declarator_arr '[' INT_CONSTANT ']'
		{
			$$.name = $1.name;
			symtab* local_symtab = table_stack.top();
			row * r = local_symtab->st[$$.name];
			r->size *= stoi($3);
			r->type += "["+$3+"]";
		}
		;
declarator:
	declarator_arr
		{
			$$.name= $1.name;

		}
		|
	'*' declarator
		{
			$$.name = $2.name;
			symtab* local_symtab = table_stack.top();
			row * r = local_symtab->st[$$.name];
			r->type = "*"+r->type;
		}
		;
compound_statement:
	'{' '}'
		{	
			seq_astnode* node = new seq_astnode();
			vector<statement_astnode*> *vec = new vector<statement_astnode*>();
			node->stmts = vec;
			$$.ast=node;
		}
		|
	'{' {
		vector<statement_astnode*>* exp_list = new vector<statement_astnode*>();
		local_exprn.push((vector<void*>* )exp_list);
	} statement_list '}'
		{
			seq_astnode* node = new seq_astnode();
			node->stmts = (vector<statement_astnode*> *) local_exprn.top();
			local_exprn.pop();
			$$.ast=node;
		}
		|

	'{' declaration_list '}'
		{
			seq_astnode* node = new seq_astnode();
			vector<statement_astnode*> *vec = new vector<statement_astnode*>();
			node->stmts = vec;
			$$.ast=node;

		}
		|

	'{' declaration_list
	{
		vector<statement_astnode*>* exp_list = new vector<statement_astnode*>();
		local_exprn.push((vector<void*>*) exp_list);
	}  statement_list '}'
		{
			seq_astnode* node = new seq_astnode();
			node->stmts = (vector<statement_astnode*> *) local_exprn.top();
			local_exprn.pop();
			$$.ast=node;
		}
		;
statement_list:
	statement
		{
			$$.ast=$1.ast;
			std::vector<statement_astnode*>* vec = (vector<statement_astnode*>*)local_exprn.top();
			vec->push_back((statement_astnode*)$1.ast);
		
		}
		|
	statement_list statement
		{
			$$.ast=$2.ast;
			vector<statement_astnode*>* vec = (vector<statement_astnode*>*)local_exprn.top();
			vec->push_back((statement_astnode*)$2.ast);
		}
		;
statement:
	';'
		{
			empty_astnode *node = new empty_astnode();
			$$.ast=node;
		}
		|
	'{'  {
		vector<statement_astnode*>* exp_list = new vector<statement_astnode*>();
		local_exprn.push((vector<void*>* )exp_list);
	}statement_list '}'
		{
			seq_astnode* node = new seq_astnode();
			node->stmts = (vector<statement_astnode*> *) local_exprn.top();
			local_exprn.pop();
			$$.ast=node;
			
		}
		|
	selection_statement
		{
			$$.ast=$1.ast;

		}
		|
	iteration_statement
		{
			$$.ast=$1.ast;
		}
		|
	assignment_statement
		{
			$$.ast=$1.ast;
		}
		|
	procedure_call
		{
			$$.ast=$1.ast;
		}
		|
	printf_call
		{

		}
		|
	RETURN expression ';'
		{
			return_astnode * node = new return_astnode();
			node->exp  = (exp_astnode*) $2.ast;
			$$.ast=node;
			row* r = func_list.top();
			if(r->type=="int" && $2.type=="float"){
				op_unary_astnode* a = new op_unary_astnode();
				a->exp = (exp_astnode*) $2.ast;
				a->str="TO_INT";
				node->exp = (exp_astnode*) a;
			}
			else if($2.type=="int" && r->type=="float"){
				op_unary_astnode* a = new op_unary_astnode();
				a->exp = (exp_astnode*) $2.ast;
				a->str="TO_FLOAT";
				node->exp = (exp_astnode*) a;
			}
			else {
				string s1=$2.type;
				string s2=r->type;
				size_t f1=s1.find('(');
				if(f1==string::npos){
					f1=s1.find('[');
					if(f1!=string::npos){
						s1=s1.substr(0,f1)+"(*)"+s1.substr(s1.find(']')+1);
					}
					else if(s1[s1.size()-1]=='*'){
						s1=s1.substr(0,s1.size()-1)+"(*)";
					}
				}
				size_t f2=s2.find('(');
				if(f2==string::npos){
					f2=s2.find('[');
					if(f2!=string::npos){
						s2=s2.substr(0,f2)+"(*)"+s2.substr(s2.find(']')+1);
					}
					else if(s2[s2.size()-1]=='*'){
						s2=s2.substr(0,s2.size()-1)+"(*)";
					}
				}
				if(s1==s2){
					
				}
				else {
					error(@1,"Incompatible type "+$2.type+" returned, expected type "+r->type);
				}
			}

		}
		;
assignment_expression:
	unary_expression '=' expression
		{
			if($1.lvalue==false){
				error(@1,"Left operand of assignment should have an lvalue");
			}
			assignE_astnode * node = new assignE_astnode();
			node->exp1 = (exp_astnode*) $1.ast;
			node->exp2 = (exp_astnode*) $3.ast;
			$$.ast=node;
			if($1.type=="int" && $3.type=="float"){
				op_unary_astnode* a = new op_unary_astnode();
				a->exp = (exp_astnode*) $3.ast;
				a->str="TO_INT";
				node->exp2 = (exp_astnode*) a;
			}
			else if($3.type=="int" && $1.type=="float"){
				op_unary_astnode* a = new op_unary_astnode();
				a->exp = (exp_astnode*) $3.ast;
				a->str="TO_FLOAT";
				node->exp2 = (exp_astnode*) a;
			}
			else if($1.is_pointer() && $3.type=="int" && $3.name=="0"){

			}
			else if ($1.is_pointer() && $3.type=="void*"){}
			else if ($3.is_pointer() && $1.type=="void*"){}
			else if ($1.is_array()){
				error(@1,"Incompatible assignment when assigning to type "+$1.type+" from type "+$3.type);
			}
			else {
				string s1=$1.type;
				string s2=$3.type;
				size_t f1=s1.find('(');
				if(f1==string::npos){
					f1=s1.find('[');
					if(f1!=string::npos){
						s1=s1.substr(0,f1)+"(*)"+s1.substr(s1.find(']')+1);
					}
					else if(s1[s1.size()-1]=='*'){
						s1=s1.substr(0,s1.size()-1)+"(*)";
					}
				}
				size_t f2=s2.find('(');
				if(f2==string::npos){
					f2=s2.find('[');
					if(f2!=string::npos){
						s2=s2.substr(0,f2)+"(*)"+s2.substr(s2.find(']')+1);
					}
					else if(s2[s2.size()-1]=='*'){
						s2=s2.substr(0,s2.size()-1)+"(*)";
					}
				}
				if(s1==s2){
					
				}
				else {
					error(@1,"Incompatible assignment when assigning to type "+$1.type+" from type "+$3.type);
				}
			}
		}
		;
assignment_statement:
	assignment_expression ';'
		{
			assignS_astnode * node = new assignS_astnode();
			node->exp1 = (exp_astnode*)(((assignE_astnode*)$1.ast)->exp1);
			node->exp2 = (exp_astnode*)(((assignE_astnode*)$1.ast)->exp2);
			$$.ast=node;
		}
		;
procedure_call:
	IDENTIFIER '(' ')' ';'
		{
			proccall_astnode * node = new proccall_astnode();
			identifier_astnode * node1 = new identifier_astnode();
			vector<exp_astnode*> *vec = new vector<exp_astnode*>();
			node->exps = vec;
			node1->str = $1;
			node->name = node1;
			$$.ast=node;
			if($1!="printf" && $1!="scanf"){
			if(gst->st.find($1)==gst->st.end()){
				error(@1,"Procedure \""+$1+"\" not declared");
			}
			symtab* fst = gst->st[$1]->next;
			for (auto i:fst->st){
				row * r = i.second;
				if(r->offset >=8)error(@1,"Procedure \""+$1+"\" called with too few arguments");
			} 
		}
		}
		|
	IDENTIFIER '(' new_nonterm
	expression_list ')' ';'
		{
			proccall_astnode * node = new proccall_astnode();
			identifier_astnode * node1 = new identifier_astnode();
			node1->str = $1;
			node->name = node1;
			vector<exp_astnode*> *vec = (vector<exp_astnode*>*)local_exprn.top();
			node->exps = vec;
			local_exprn.pop();
			$$.ast = node;
			// std::cout<<"line 471"<<std::endl;
			if($1!="printf" && $1!="scanf"){
				if(gst->st.find($1)==gst->st.end()){
					error(@1,"Procedure \""+$1+"\" not declared");
				}
			symtab* fst = gst->st[$1]->next;
			map<int,string> m;
			for (auto i:fst->st){
				row * r = i.second;
				if(r->offset <=0)continue;
				m.insert({-r->offset,r->type});
			} 
			vector<string> vec2;
			for(auto i:m)vec2.push_back(i.second);

			vector<string> *vec1 = local_type.top();
			local_type.pop();
			// check if vec1 and vec size are same
			if((*vec1).size()>vec2.size()){
				error(@1,"Procedure \""+$1+"\" called with too many arguments");
			}
			if((*vec1).size()<vec2.size()){
				error(@1,"Procedure \""+$1+"\" called with too few arguments");
			}
			for (int i=0;i<(*vec1).size();i++){
				string s1=vec2[i];
				string s2=(*vec1)[i];
				if(s1=="int" && s2=="float"){
					op_unary_astnode* a = new op_unary_astnode();
					a->exp = (exp_astnode*) (*(node->exps))[i];
					a->str="TO_INT";
					(*(node->exps))[i] = (exp_astnode*) a;
				}
				else if(s2=="int" && s1=="float"){
					op_unary_astnode* a = new op_unary_astnode();
					a->exp = (exp_astnode*) (*(node->exps))[i];
					a->str="TO_FLOAT";
					(*(node->exps))[i] = (exp_astnode*) a;
				}
				else if(is_pointer1(s1)&&s2=="void*"){}
				else if(is_pointer1(s2)&&s1=="void*"){}
				else {
					string s3=s1;
					string s4=s2;
					size_t f1=s1.find('(');
					if(f1==string::npos){
						f1=s1.find('[');
						if(f1!=string::npos){
							s1=s1.substr(0,f1)+"(*)"+s1.substr(s1.find(']')+1);
						}
						else if(s1[s1.size()-1]=='*'){
							s1=s1.substr(0,s1.size()-1)+"(*)";
						}
					}
					size_t f2=s2.find('(');
					if(f2==string::npos){
						f2=s2.find('[');
						if(f2!=string::npos){
							s2=s2.substr(0,f2)+"(*)"+s2.substr(s2.find(']')+1);
						}
						else if(s2[s2.size()-1]=='*'){
							s2=s2.substr(0,s2.size()-1)+"(*)";
						}
					}
					if(s1!=s2){
						error(@1,"Expected type "+s3+" but argument is of type "+s4);
					}
					
				}
			}
		}
		}
		;
expression:
	logical_and_expression
		{
			$$.ast=$1.ast;
			$$.type = $1.type;
			$$.name = $1.name;
			$$.lvalue = $1.lvalue;
		}
		|
	expression OR_OP logical_and_expression
		{
			$$.lvalue = false;
			op_binary_astnode * node =  new op_binary_astnode();
			node->exp1 = (exp_astnode*)$1.ast;
			node->exp2 = (exp_astnode*)$3.ast;
			node->str = "OR_OP";
			$$.ast=node;
			$$.type = "int";
			if(!$1.is_int() && !$1.is_float() && !$1.is_pointer()){
				error(@1,"Invalid operand of ||, not scalar or pointer");
			}
			if(!$3.is_int() && !$3.is_float() && !$3.is_pointer()){
				error(@1,"Invalid operand of ||, not scalar or pointer");
			}
		}
		;
logical_and_expression:
	equality_expression
		{
			$$.ast=$1.ast;
			$$.type = $1.type;
			$$.name = $1.name;
			$$.lvalue = $1.lvalue;
		}
		|
	logical_and_expression AND_OP equality_expression
		{
			$$.lvalue = false;
			op_binary_astnode * node =  new op_binary_astnode();
			node->exp1 = (exp_astnode*)$1.ast;
			node->exp2 = (exp_astnode*)$3.ast;
			node->str = "AND_OP";
			$$.ast=node;
			$$.type="int";
			if(!$1.is_int() && !$1.is_float() && !$1.is_pointer()){
				error(@1,"Invalid operand of &&, not scalar or pointer");
			}
			if(!$3.is_int() && !$3.is_float() && !$3.is_pointer()){
				error(@1,"Invalid operand of &&, not scalar or pointer");
			}
		}
		;
equality_expression:
	relational_expression
		{
			$$.ast=$1.ast;
			$$.type = $1.type;
			$$.name = $1.name;
			$$.lvalue = $1.lvalue;
		}
		|
	equality_expression EQ_OP relational_expression
		{
			$$.lvalue = false;
			op_binary_astnode * node =  new op_binary_astnode();
			node->exp1 = (exp_astnode*)$1.ast;
			node->exp2 = (exp_astnode*)$3.ast;
			node->str = "EQ_OP";
			$$.ast=node;
			$$.type="int";
			// cout<<$1.type<<"ABC"<<$3.type<<endl;
			if($1.type=="int" && $3.type =="int"){
				node->str+="_INT";
				
			}
			else if ($1.type=="float" && $3.type =="float"){
				node->str+="_FLOAT";
				
			}
			else if ($1.type=="int" && $3.type =="float"){
				node->str += "_FLOAT";
				op_unary_astnode* a = new op_unary_astnode();
				a->exp = (exp_astnode*) $1.ast;
				a->str="TO_FLOAT";
				node->exp1 = (exp_astnode*) a;
		
			}
			else if ($3.type=="int" && $1.type =="float"){
				node->str += "_FLOAT";
				op_unary_astnode* a = new op_unary_astnode();
				a->exp = (exp_astnode*) $3.ast;
				a->str="TO_FLOAT";
				node->exp2 = (exp_astnode*) a;
			
			}
			// else if($3.is_pointer() && ($1.type=="int"||$1.type=="float")){
			// 	error(@1,"Invalid operands types for binary ==, \""+$1.type+"\" and \""+$3.type+"\"");
			// }
			// else if($1.is_pointer() && ($3.type=="int"||$3.type=="float")){
			// 	error(@1,"Invalid operands types for binary ==, \""+$1.type+"\" and \""+$3.type+"\"");
			// }
			else {
				string s1=$1.type;
				string s2=$3.type;
				size_t f1=s1.find('(');
				if(f1==string::npos){
					f1=s1.find('[');
					if(f1!=string::npos){
						s1=s1.substr(0,f1)+"(*)"+s1.substr(s1.find(']')+1);
					}
					else if(s1[s1.size()-1]=='*'){
						s1=s1.substr(0,s1.size()-1)+"(*)";
					}
				}
				size_t f2=s2.find('(');
				if(f2==string::npos){
					f2=s2.find('[');
					if(f2!=string::npos){
						s2=s2.substr(0,f2)+"(*)"+s2.substr(s2.find(']')+1);
					}
					else if(s2[s2.size()-1]=='*'){
						s2=s2.substr(0,s2.size()-1)+"(*)";
					}
				}
				if(s1==s2){
					node->str+="_INT";
					$$.type="int";
				}
				else {
					node->str+="_INT";
					$$.type="int";
					// error(@1,"Invalid operand types for binary == ,"+$1.type+" and "+$3.type);
				}
			}
		}
		|
	equality_expression NE_OP relational_expression
		{
			$$.lvalue = false;
			op_binary_astnode * node =  new op_binary_astnode();
			node->exp1 = (exp_astnode*)$1.ast;
			node->exp2 = (exp_astnode*)$3.ast;
			node->str = "NE_OP";
			$$.ast=node;
			$$.type="int";
			if($1.type=="int" && $3.type =="int"){
				node->str+="_INT";
				
			}
			else if ($1.type=="float" && $3.type =="float"){
				node->str+="_FLOAT";
				
			}
			else if ($1.type=="int" && $3.type =="float"){
				node->str += "_FLOAT";
				op_unary_astnode* a = new op_unary_astnode();
				a->exp = (exp_astnode*) $1.ast;
				a->str="TO_FLOAT";
				node->exp1 = (exp_astnode*) a;
		
			}
			else if ($3.type=="int" && $1.type =="float"){
				node->str += "_FLOAT";
				op_unary_astnode* a = new op_unary_astnode();
				a->exp = (exp_astnode*) $3.ast;
				a->str="TO_FLOAT";
				node->exp2 = (exp_astnode*) a;
			
			}
			else {
				string s1=$1.type;
				string s2=$3.type;
				size_t f1=s1.find('(');
				if(f1==string::npos){
					f1=s1.find('[');
					if(f1!=string::npos){
						s1=s1.substr(0,f1)+"(*)"+s1.substr(s1.find(']')+1);
					}
					else if(s1[s1.size()-1]=='*'){
						s1=s1.substr(0,s1.size()-1)+"(*)";
					}
				}
				size_t f2=s2.find('(');
				if(f2==string::npos){
					f2=s2.find('[');
					if(f2!=string::npos){
						s2=s2.substr(0,f2)+"(*)"+s2.substr(s2.find(']')+1);
					}
					else if(s2[s2.size()-1]=='*'){
						s2=s2.substr(0,s2.size()-1)+"(*)";
					}
				}
				if(s1==s2){
					node->str+="_INT";
					$$.type="int";
				}
				else {
					node->str+="_INT";
					$$.type="int";
					// error(@1,"Invalid operand types for binary != ,"+$1.type+" and "+$3.type);
				}
			}
		}
		;
relational_expression:
	additive_expression
		{
			$$.ast=$1.ast;
			$$.type = $1.type;
			$$.name = $1.name;
			$$.lvalue = $1.lvalue;
		}
		|
	relational_expression '<' additive_expression
		{
			$$.lvalue = false;	
			op_binary_astnode * node =  new op_binary_astnode();
			node->exp1 = (exp_astnode*)$1.ast;
			node->exp2 = (exp_astnode*)$3.ast;
			node->str = "LT_OP";
			$$.ast=node;
			$$.type="int";
			if($1.type=="int" && $3.type =="int"){
				node->str+="_INT";
				
			}
			else if ($1.type=="float" && $3.type =="float"){
				node->str+="_FLOAT";
				
			}
			else if ($1.type=="int" && $3.type =="float"){
				node->str += "_FLOAT";
				op_unary_astnode* a = new op_unary_astnode();
				a->exp = (exp_astnode*) $1.ast;
				a->str="TO_FLOAT";
				node->exp1 = (exp_astnode*) a;
		
			}
			else if ($3.type=="int" && $1.type =="float"){
				node->str += "_FLOAT";
				op_unary_astnode* a = new op_unary_astnode();
				a->exp = (exp_astnode*) $3.ast;
				a->str="TO_FLOAT";
				node->exp2 = (exp_astnode*) a;
			
			}
			else {
				string s1=$1.type;
				string s2=$3.type;
				size_t f1=s1.find('(');
				if(f1==string::npos){
					f1=s1.find('[');
					if(f1!=string::npos){
						s1=s1.substr(0,f1)+"(*)"+s1.substr(s1.find(']')+1);
					}
					else if(s1[s1.size()-1]=='*'){
						s1=s1.substr(0,s1.size()-1)+"(*)";
					}
				}
				size_t f2=s2.find('(');
				if(f2==string::npos){
					f2=s2.find('[');
					if(f2!=string::npos){
						s2=s2.substr(0,f2)+"(*)"+s2.substr(s2.find(']')+1);
					}
					else if(s2[s2.size()-1]=='*'){
						s2=s2.substr(0,s2.size()-1)+"(*)";
					}
				}
				if(s1==s2){
					node->str+="_INT";
					$$.type="int";
				}
				else {
					error(@1,"Invalid operand types for binary < ,"+$1.type+" and "+$3.type);
				}

			}
		}
		|
	relational_expression '>' additive_expression
		{
			$$.lvalue = false;
			op_binary_astnode * node =  new op_binary_astnode();
			node->exp1 = (exp_astnode*)$1.ast;
			node->exp2 = (exp_astnode*)$3.ast;
			node->str = "GT_OP";
			$$.ast=node;
			$$.type="int";
			if($1.type=="int" && $3.type =="int"){
				node->str+="_INT";
				
			}
			else if ($1.type=="float" && $3.type =="float"){
				node->str+="_FLOAT";
				
			}
			else if ($1.type=="int" && $3.type =="float"){
				node->str += "_FLOAT";
				op_unary_astnode* a = new op_unary_astnode();
				a->exp = (exp_astnode*) $1.ast;
				a->str="TO_FLOAT";
				node->exp1 = (exp_astnode*) a;
		
			}
			else if ($3.type=="int" && $1.type =="float"){
				node->str += "_FLOAT";
				op_unary_astnode* a = new op_unary_astnode();
				a->exp = (exp_astnode*) $3.ast;
				a->str="TO_FLOAT";
				node->exp2 = (exp_astnode*) a;
			
			}
			else {
				string s1=$1.type;
				string s2=$3.type;
				size_t f1=s1.find('(');
				if(f1==string::npos){
					f1=s1.find('[');
					if(f1!=string::npos){
						s1=s1.substr(0,f1)+"(*)"+s1.substr(s1.find(']')+1);
					}
					else if(s1[s1.size()-1]=='*'){
						s1=s1.substr(0,s1.size()-1)+"(*)";
					}
				}
				size_t f2=s2.find('(');
				if(f2==string::npos){
					f2=s2.find('[');
					if(f2!=string::npos){
						s2=s2.substr(0,f2)+"(*)"+s2.substr(s2.find(']')+1);
					}
					else if(s2[s2.size()-1]=='*'){
						s2=s2.substr(0,s2.size()-1)+"(*)";
					}
				}
				if(s1==s2){
					node->str+="_INT";
					$$.type="int";
				}
				else {
					error(@1,"Invalid operand types for binary > ,"+$1.type+" and "+$3.type);
				}
			}
		}
		|
	relational_expression LE_OP additive_expression
		{
			$$.lvalue = false;
			op_binary_astnode * node =  new op_binary_astnode();
			node->exp1 = (exp_astnode*)$1.ast;
			node->exp2 = (exp_astnode*)$3.ast;
			node->str = "LE_OP";
			$$.ast=node;
			$$.type="int";
			if($1.type=="int" && $3.type =="int"){
				node->str+="_INT";
				
			}
			else if ($1.type=="float" && $3.type =="float"){
				node->str+="_FLOAT";
				
			}
			else if ($1.type=="int" && $3.type =="float"){
				node->str += "_FLOAT";
				op_unary_astnode* a = new op_unary_astnode();
				a->exp = (exp_astnode*) $1.ast;
				a->str="TO_FLOAT";
				node->exp1 = (exp_astnode*) a;
		
			}
			else if ($3.type=="int" && $1.type =="float"){
				node->str += "_FLOAT";
				op_unary_astnode* a = new op_unary_astnode();
				a->exp = (exp_astnode*) $3.ast;
				a->str="TO_FLOAT";
				node->exp2 = (exp_astnode*) a;
			
			}
			else {
				string s1=$1.type;
				string s2=$3.type;
				size_t f1=s1.find('(');
				if(f1==string::npos){
					f1=s1.find('[');
					if(f1!=string::npos){
						s1=s1.substr(0,f1)+"(*)"+s1.substr(s1.find(']')+1);
					}
					else if(s1[s1.size()-1]=='*'){
						s1=s1.substr(0,s1.size()-1)+"(*)";
					}
				}
				size_t f2=s2.find('(');
				if(f2==string::npos){
					f2=s2.find('[');
					if(f2!=string::npos){
						s2=s2.substr(0,f2)+"(*)"+s2.substr(s2.find(']')+1);
					}
					else if(s2[s2.size()-1]=='*'){
						s2=s2.substr(0,s2.size()-1)+"(*)";
					}
				}
				if(s1==s2){
					node->str+="_INT";
					$$.type="int";
				}
				else{
					error(@1,"Invalid operand types for binary <= ,"+$1.type+" and "+$3.type);
				}
			}
		}
		|
	relational_expression GE_OP additive_expression
		{
			$$.lvalue = false;
			op_binary_astnode * node =  new op_binary_astnode();
			node->exp1 = (exp_astnode*)$1.ast;
			node->exp2 = (exp_astnode*)$3.ast;
			node->str = "GE_OP";
			$$.ast=node;
			$$.type="int";
			if($1.type=="int" && $3.type =="int"){
				node->str+="_INT";
				
			}
			else if ($1.type=="float" && $3.type =="float"){
				node->str+="_FLOAT";
				
			}
			else if ($1.type=="int" && $3.type =="float"){
				node->str += "_FLOAT";
				op_unary_astnode* a = new op_unary_astnode();
				a->exp = (exp_astnode*) $1.ast;
				a->str="TO_FLOAT";
				node->exp1 = (exp_astnode*) a;
		
			}
			else if ($3.type=="int" && $1.type =="float"){
				node->str += "_FLOAT";
				op_unary_astnode* a = new op_unary_astnode();
				a->exp = (exp_astnode*) $3.ast;
				a->str="TO_FLOAT";
				node->exp2 = (exp_astnode*) a;
			
			}
			else {
				string s1=$1.type;
				string s2=$3.type;
				size_t f1=s1.find('(');
				if(f1==string::npos){
					f1=s1.find('[');
					if(f1!=string::npos){
						s1=s1.substr(0,f1)+"(*)"+s1.substr(s1.find(']')+1);
					}
					else if(s1[s1.size()-1]=='*'){
						s1=s1.substr(0,s1.size()-1)+"(*)";
					}
				}
				size_t f2=s2.find('(');
				if(f2==string::npos){
					f2=s2.find('[');
					if(f2!=string::npos){
						s2=s2.substr(0,f2)+"(*)"+s2.substr(s2.find(']')+1);
					}
					else if(s2[s2.size()-1]=='*'){
						s2=s2.substr(0,s2.size()-1)+"(*)";
					}
				}
				if(s1==s2){
					node->str+="_INT";
					$$.type="int";
				}
				else{
					error(@1,"Invalid operand types for binary >= ,"+$1.type+" and "+$3.type);
				}

			}
		}
		;
additive_expression:
	multiplicative_expression
		{
			$$.ast=$1.ast;
			$$.type = $1.type;
			$$.name = $1.name;
			$$.lvalue = $1.lvalue;
		}
		|
	additive_expression '+' multiplicative_expression
		{
			$$.lvalue = false;
			op_binary_astnode * node =  new op_binary_astnode();
			node->exp1 = (exp_astnode*)$1.ast;
			node->exp2 = (exp_astnode*)$3.ast;
			node->str = "PLUS";
			$$.ast=node;
			if($1.type=="int" && $3.type =="int"){
				node->str+="_INT";
				$$.type="int";
			}
			else if ($1.type=="float" && $3.type =="float"){
				node->str+="_FLOAT";
				$$.type="float";
			}
			else if ($1.type=="int" && $3.type =="float"){
				node->str += "_FLOAT";
				op_unary_astnode* a = new op_unary_astnode();
				a->exp = (exp_astnode*) $1.ast;
				a->str="TO_FLOAT";
				node->exp1 = (exp_astnode*) a;
				$$.type="float";
			}
			else if ($3.type=="int" && $1.type =="float"){
				node->str += "_FLOAT";
				op_unary_astnode* a = new op_unary_astnode();
				a->exp = (exp_astnode*) $3.ast;
				a->str="TO_FLOAT";
				node->exp2 = (exp_astnode*) a;
				$$.type="float";
			}
			else if ($1.type == "int" && $3.is_pointer()){
				node->str+="_INT";
				string s1=$3.type;
				size_t f1=s1.find('(');
				if(f1==string::npos){
					f1=s1.find('[');
					if(f1!=string::npos){
						s1=s1.substr(0,f1)+"(*)"+s1.substr(s1.find(']')+1);
					}
					else if(s1[s1.size()-1]=='*'){
						s1=s1.substr(0,s1.size()-1)+"(*)";
					}
				}
				$$.type=s1;
			}
			else if ($3.type =="int" && $1.is_pointer()){
				node->str+="_INT";
				string s1=$1.type;
				size_t f1=s1.find('(');
				if(f1==string::npos){
					f1=s1.find('[');
					if(f1!=string::npos){
						s1=s1.substr(0,f1)+"(*)"+s1.substr(s1.find(']')+1);
					}
					else if(s1[s1.size()-1]=='*'){
						s1=s1.substr(0,s1.size()-1)+"(*)";
					}
				}
				$$.type=s1;
			}
			else {
				error(@1,"Invalid operand types for binary + ,"+$1.type+" and "+$3.type);
			}
		}
		|
	additive_expression '-' multiplicative_expression
		{
			$$.lvalue = false;
			op_binary_astnode * node =  new op_binary_astnode();
			node->exp1 = (exp_astnode*)$1.ast;
			node->exp2 = (exp_astnode*)$3.ast;
			node->str = "MINUS";
			$$.ast=node;
			if($1.type=="int" && $3.type =="int"){
				node->str+="_INT";
				$$.type="int";
			}
			else if ($1.type=="float" && $3.type =="float"){
				node->str+="_FLOAT";
				$$.type="float";
			}
			else if ($1.type=="int" && $3.type =="float"){
				node->str += "_FLOAT";
				op_unary_astnode* a = new op_unary_astnode();
				a->exp = (exp_astnode*) $1.ast;
				a->str="TO_FLOAT";
				node->exp1 = (exp_astnode*) a;
				$$.type="float";
			}
			else if ($3.type=="int" && $1.type =="float"){
				node->str += "_FLOAT";
				op_unary_astnode* a = new op_unary_astnode();
				a->exp = (exp_astnode*) $3.ast;
				a->str="TO_FLOAT";
				node->exp2 = (exp_astnode*) a;
				$$.type="float";
			}
			else if ($3.type == "int"){
				node->str += "_INT";
				if($1.is_pointer()){
					string s1=$1.type;
					size_t f1=s1.find('(');
					if(f1==string::npos){
						f1=s1.find('[');
						if(f1!=string::npos){
							s1=s1.substr(0,f1)+"(*)"+s1.substr(s1.find(']')+1);
						}
						else if(s1[s1.size()-1]=='*'){
							s1=s1.substr(0,s1.size()-1)+"(*)";
						}
					}
					$$.type=s1;
				}
				else {
					error(@1,"Invalid operand types for binary - ,"+$1.type+" and "+$3.type);
				}
			}
			else {
				string s1=$1.type;
				string s2=$3.type;
				size_t f1=s1.find('(');
				if(f1==string::npos){
					f1=s1.find('[');
					if(f1!=string::npos){
						s1=s1.substr(0,f1)+"(*)"+s1.substr(s1.find(']')+1);
					}
					else if(s1[s1.size()-1]=='*'){
						s1=s1.substr(0,s1.size()-1)+"(*)";
					}
				}
				size_t f2=s2.find('(');
				if(f2==string::npos){
					f2=s2.find('[');
					if(f2!=string::npos){
						s2=s2.substr(0,f2)+"(*)"+s2.substr(s2.find(']')+1);
					}
					else if(s2[s2.size()-1]=='*'){
						s2=s2.substr(0,s2.size()-1)+"(*)";
					}
				}
				if(s1==s2){
					node->str+="_INT";
					$$.type="int";
				}
				else {
					error(@1,"Invalid operand types for binary - ,"+$1.type+" and "+$3.type);
				}
			}
		}
		;
unary_expression:
	postfix_expression
		{
			$$.ast=$1.ast;
			$$.type = $1.type;
			$$.name = $1.name;
			$$.lvalue = $1.lvalue;
		}
		|
	unary_operator unary_expression
		{
			op_unary_astnode *node = new op_unary_astnode();
			node->str=$1.name;
			node->exp = (exp_astnode*)$2.ast;
			$$.ast=node;
			if($1.name == "DEREF"){
				$$.lvalue = true;
				string s = $2.type;
				if($2.is_void()){
					error(@1,"Invalid operand type "+$2.type+" for unary operator *");
				}
				size_t found = s.find('(');
				if(found!= string::npos){
					$$.type = s.substr(0,found)+s.substr(found+3);
					
				}
				else{	
					found = s.find('[');
					if(found!= string::npos){
						$$.type = s.substr(0,found)+s.substr(s.find(']')+1);
					}
					else {
						found = s.find('*');
						if(found!=string::npos){
							$$.type = s.substr(0,found)+s.substr(found+1);
						}
						else {
							error(@1,"Invalid operand type "+$2.type+" for unary operator *");
						}
					}
				}
				
			}
			else if ($1.name == "UMINUS"){
				$$.type = $2.type;
				$$.lvalue = false;
				if($2.type!="int" && $2.type!="float"){
					error(@1,"Operand of unary - should be an int or float");
				}
			}
			else if ($1.name == "NOT"){
				$$.type = "int";
				$$.lvalue = false;
				// cout<<"ABC\t"<<$2.type<<endl;
				if(!$2.is_int() && !$2.is_float() && !$2.is_pointer()){
				error(@1,"Operand of NOT should be an int or float or pointer");
				}

			}
			else if ($1.name == "ADDRESS"){
				string s = $2.type;
				$$.lvalue = false;
				size_t found = s.find ('[');
				if(found!=string::npos){
					$$.type = s.substr(0,found)+"(*)"+s.substr(found);
				}
				else {
					$$.type = s+"*";
				}
				if($2.lvalue==false){
					error(@1,"Operand of & should  have lvalue");
				}
			}
			

		}
		;
multiplicative_expression:
	unary_expression
		{
			$$.ast=$1.ast;
			$$.type = $1.type;
			$$.name = $1.name;
			$$.lvalue = $1.lvalue;
		}
		|
	multiplicative_expression '*' unary_expression
		{
			$$.lvalue = false;
			op_binary_astnode * node =  new op_binary_astnode();
			node->exp1 = (exp_astnode*)$1.ast;
			node->exp2 = (exp_astnode*)$3.ast;
			node->str = "MULT";
			$$.ast=node;
			if($1.type=="int" && $3.type =="int"){
				node->str+="_INT";
				$$.type="int";
			}
			else if ($1.type=="float" && $3.type =="float"){
				node->str+="_FLOAT";
				$$.type="float";
			}
			else if ($1.type=="int" && $3.type =="float"){
				node->str += "_FLOAT";
				op_unary_astnode* a = new op_unary_astnode();
				a->exp = (exp_astnode*) $1.ast;
				a->str="TO_FLOAT";
				node->exp1 = (exp_astnode*) a;
				$$.type="float";
			}
			else if ($3.type=="int" && $1.type =="float"){
				node->str += "_FLOAT";
				op_unary_astnode* a = new op_unary_astnode();
				a->exp = (exp_astnode*) $3.ast;
				a->str="TO_FLOAT";
				node->exp2 = (exp_astnode*) a;
				$$.type="float";
			}
			else{
				error(@1,"Invalid operand types for binary * ,"+$1.type+" and "+$3.type);
			}
		}
		|
	multiplicative_expression '/' unary_expression
		{
			$$.lvalue = false;
			op_binary_astnode * node =  new op_binary_astnode();
			node->exp1 = (exp_astnode*)$1.ast;
			node->exp2 = (exp_astnode*)$3.ast;
			node->str = "DIV";
			$$.ast=node;
			if($1.type=="int" && $3.type =="int"){
				node->str+="_INT";
				$$.type="int";
			}
			else if ($1.type=="float" && $3.type =="float"){
				node->str+="_FLOAT";
				$$.type="float";
			}
			else if ($1.type=="int" && $3.type =="float"){
				node->str += "_FLOAT";
				op_unary_astnode* a = new op_unary_astnode();
				a->exp = (exp_astnode*) $1.ast;
				a->str="TO_FLOAT";
				node->exp1 = (exp_astnode*) a;
				$$.type="float";
			}
			else if ($3.type=="int" && $1.type =="float"){
				node->str += "_FLOAT";
				op_unary_astnode* a = new op_unary_astnode();
				a->exp = (exp_astnode*) $3.ast;
				a->str="TO_FLOAT";
				node->exp2 = (exp_astnode*) a;
				$$.type="float";
			}
			else {
				error(@1,"Invalid operand types for binary / ,"+$1.type+" and "+$3.type);
			}
		}
		;

new_nonterm: %empty {vector<exp_astnode*>* exp_list = new vector<exp_astnode*>();
		local_exprn.push((vector<void*>*) exp_list);
		vector<string>* type_list = new vector<string>();
		local_type.push(type_list);};

postfix_expression:
	primary_expression
		{
			$$.ast = $1.ast;
			$$.type = $1.type;
			$$.name = $1.name;
			$$.lvalue = $1.lvalue;
		}
		|
	postfix_expression '[' expression ']'
		{
			$$.lvalue = true;
			arrayref_astnode * node = new arrayref_astnode();
			node->exp1 = (exp_astnode*)$1.ast;
			node->exp2 = (exp_astnode*)$3.ast;
			$$.ast = node;
			string s = $1.type;

			if($3.type!="int"){
				error(@1,"Array substrict is not an integer");
			}
			if($1.is_void()){
				error(@1,"Expression is of type "+$1.type);
			}

			size_t found = s.find('(');
			if(found!= string::npos){
				$$.type = s.substr(0,found)+s.substr(found+3);
			}
			else{	
				found = s.find('[');
				if(found!= string::npos){
					$$.type = s.substr(0,found)+s.substr(s.find(']')+1);
				}
				else {
					found = s.find('*');
					if(found!=string::npos){
						$$.type = s.substr(0,found)+s.substr(found+1);
					}
					else {
						error(@1,"Subscripted value is neither array nor pointer");
					}
				}
			}
		}
		|
	IDENTIFIER '(' ')'
		{
			$$.lvalue = false;
			funcall_astnode * node = new funcall_astnode();
			identifier_astnode * node1 = new identifier_astnode();
			node1->str = $1;
			node->name = node1;
			vector<exp_astnode*> *vec = new vector<exp_astnode*>();
			node->exps = vec;
			// node->exps = vector<exp_astnode*> ();
			$$.ast = node; 
			if(gst->st.find($1)==gst->st.end()){
				error(@1,"Function \""+$1+"\" not declared");
			}
			$$.type = gst->st[$1]->type;
			symtab* fst = gst->st[$1]->next;
			for (auto i:fst->st){
				row * r = i.second;
				if(r->offset >=8)error(@1,"Function \""+$1+"\" called with too few arguments");
			} 
		}
		|
	IDENTIFIER '(' new_nonterm expression_list ')'
		{
			$$.lvalue = false;
			funcall_astnode * node = new funcall_astnode();
			identifier_astnode * node1 = new identifier_astnode();
			node1->str = $1;
			node->name = node1;
			node->exps = (vector<exp_astnode*>*) local_exprn.top();
			local_exprn.pop();
			$$.ast = node; 
			if($1!="printf" && $1!="scanf"){
				if(gst->st.find($1)==gst->st.end()){
					error(@1,"Function \""+$1+"\" not declared");
				}
				$$.type = gst->st[$1]->type;
				symtab* fst = gst->st[$1]->next;
				map<int,string> m;
				for (auto i:fst->st){
					row * r = i.second;
					if(r->offset <=0)continue;
					m.insert({-r->offset,r->type});
				} 
				vector<string> vec;
				for(auto i:m)vec.push_back(i.second);

				vector<string> *vec1 = local_type.top();
				local_type.pop();
				// check if vec1 and vec size are same
				if((*vec1).size()>vec.size()){
					error(@1,"Function \""+$1+"\" called with too many arguments");
				}
				if((*vec1).size()<vec.size()){
					error(@1,"Function \""+$1+"\" called with too few arguments");
				}
				for (int i=0;i<(*vec1).size();i++){
					string s1=vec[i];
					string s2=(*vec1)[i];
					if(s1=="int" && s2=="float"){
						op_unary_astnode* a = new op_unary_astnode();
						a->exp = (exp_astnode*) (*(node->exps))[i];
						a->str="TO_INT";
						(*(node->exps))[i] = (exp_astnode*) a;
					}
					else if(s2=="int" && s1=="float"){
						op_unary_astnode* a = new op_unary_astnode();
						a->exp = (exp_astnode*) (*(node->exps))[i];
						a->str="TO_FLOAT";
						(*(node->exps))[i] = (exp_astnode*) a;
					}
					else if(is_pointer1(s1)&&s2=="void*"){}
					else if(is_pointer1(s2)&&s1=="void*"){}
					else {
						string s3=s1;
						string s4=s2;
						size_t f1=s1.find('(');
						if(f1==string::npos){
							f1=s1.find('[');
							if(f1!=string::npos){
								s1=s1.substr(0,f1)+"(*)"+s1.substr(s1.find(']')+1);
							}
							else if(s1[s1.size()-1]=='*'){
								s1=s1.substr(0,s1.size()-1)+"(*)";
							}
						}
						size_t f2=s2.find('(');
						if(f2==string::npos){
							f2=s2.find('[');
							if(f2!=string::npos){
								s2=s2.substr(0,f2)+"(*)"+s2.substr(s2.find(']')+1);
							}
							else if(s2[s2.size()-1]=='*'){
								s2=s2.substr(0,s2.size()-1)+"(*)";
							}
						}
						if(s1==s2){
							
						}
						else {
							error(@1,"Expected type "+s3+" but argument is of type "+s4);
						}
					}
				}
			}
		}
		|
	postfix_expression '.' IDENTIFIER
		{
			$$.lvalue=true;
			member_astnode * node = new member_astnode();
			node->exp = (exp_astnode*) $1.ast;
			identifier_astnode * node1 = new identifier_astnode();;
			node1->str=$3;
			node->id = node1;
			$$.ast=node;

			if(gst->st.find($1.type)==gst->st.end()){
				error(@3,"Left operand of \".\"  is not a structure");
			}
			if(gst->st[$1.type]->next->st.find($3)==gst->st[$1.type]->next->st.end()){
				error(@3,$1.type+" has no member called "+$3);
			}
			$$.type = gst->st[$1.type]->next->st[$3]->type;

		}
		|
	postfix_expression PTR_OP IDENTIFIER
		{
			$$.lvalue = true;
			arrow_astnode * node = new arrow_astnode();
			node->exp = (exp_astnode*) $1.ast;
			identifier_astnode * node1 = new identifier_astnode();;
			node1->str=$3;
			node->id = node1;
			$$.ast=node;
			string s = $1.type;
			string s1;
			size_t found = s.find('(');
			if(found!= string::npos){
				s1 = s.substr(0,found)+s.substr(found+3);
				
			}
			else{	
				found = s.find('[');
				if(found!= string::npos){
					s1 = s.substr(0,found)+s.substr(s.find(']')+1);
				}
				else {
					found = s.find('*');
					if(found!=string::npos){
						s1 = s.substr(0,found)+s.substr(found+1);
					}
					else {
						error(@3,"Left operand of -> is not a pointer");
					}
				}
			}
			if(gst->st.find(s1)==gst->st.end()){
				error(@3,"Left operand of ->  is not a pointer to a structure");
			}
			if(gst->st[s1]->next->st.find($3)==gst->st[s1]->next->st.end()){
				error(@3,s1+" has no member called "+$3);
			}

			$$.type = gst->st[s1]->next->st[$3]->type;

			
		}
		|
	postfix_expression INC_OP
		{
			$$.lvalue = false;
			if(!$1.lvalue){
				error(@1,"Operand of ++ should have lvalue");
			}
			op_unary_astnode *node = new op_unary_astnode();
			node->exp = (exp_astnode*) $1.ast;
			node->str= "PP";
			$$.ast=node;
			$$.type = $1.type;
			if(!$1.is_int() && !$1.is_float() && !$1.is_pointer()){
				error(@1,"Operand of ++ should be an int or float or pointer");
			}
			if($1.is_array()){
				error(@1,"Operand of ++ should be an int or float or pointer");
			}
			

		}
		;
primary_expression:
	IDENTIFIER
		{
			identifier_astnode* node = new identifier_astnode();
			node->str=$1;
			$$.ast=node;
			symtab* local_symtab = table_stack.top();
			if(local_symtab->st.find($1)==local_symtab->st.end()){
				error(@1,"Identifier \""+$1+"\" has no previous decleration");
			}
			$$.type = local_symtab->st[$1]->type;
			$$.name = $1;
			$$.lvalue = true;
		}
		|
	INT_CONSTANT
		{
			intconst_astnode* node = new intconst_astnode();
			node->num=$1;
			$$.ast=node;
			$$.type = "int";
			$$.name = $1;
			$$.lvalue=false;
		}
		|
	FLOAT_CONSTANT
		{
			floatconst_astnode* node = new floatconst_astnode();
			node->num=$1;
			$$.ast=node;
			$$.type = "float";
			$$.lvalue=false;
		}
		|
	STRING_LITERAL
		{
			stringconst_astnode* node = new stringconst_astnode();
			node->str=$1;
			$$.ast=node;
			$$.type = "string";
			$$.lvalue=false;
			glob_str[$1]=curr_index;
			curr_index++;


		}
		|
	'(' expression ')'
		{
			$$.ast = $2.ast;
			$$.type = $2.type;
			$$.lvalue=$2.lvalue;
		}
		;
expression_list:
	expression
		{
			$$.ast=$1.ast;
			vector<exp_astnode*>* vec = (vector<exp_astnode*>*)local_exprn.top();
			vec->push_back((exp_astnode*)$1.ast);

			vector<string>* vec1= local_type.top();
			vec1->push_back($1.type);

			
		}
		|
	expression_list ',' expression
		{
			vector<exp_astnode*>* vec = (vector<exp_astnode*>* )local_exprn.top();
			vec->push_back((exp_astnode*)$3.ast);
			$$.ast=$3.ast;

			vector<string>* vec1= local_type.top();
			vec1->push_back($3.type);
		}
		;
unary_operator:
	'-'
		{
			$$.name="UMINUS";
		}
		|
	'!'
		{
			$$.name="NOT";
		}
		|
	'&'
		{
			$$.name="ADDRESS";
		}
		|
	'*'
		{
			$$.name="DEREF";
		}
		;
selection_statement:
	IF '(' expression ')' statement ELSE statement
		{
			if_astnode *node= new if_astnode();
			node->exp = (exp_astnode*) $3.ast;
			node->stmt1 = (statement_astnode*) $5.ast;
			node->stmt2 = (statement_astnode*) $7.ast;
			$$.ast=node;
		}
		;
iteration_statement:
	WHILE '(' expression ')' statement
		{
			while_astnode *node = new while_astnode();
			node->exp = (exp_astnode *)$3.ast;
			node->stmt = (statement_astnode *)$5.ast;
			$$.ast=node;
		}
		|
	FOR '(' assignment_expression ';' expression ';' assignment_expression ')' statement
		{
			for_astnode *node = new for_astnode();
			node->exp1=(exp_astnode*) $3.ast;
			node->exp2=(exp_astnode*) $5.ast;
			node->exp3=(exp_astnode*) $7.ast;
			node->stmt = (statement_astnode *)$9.ast;
			$$.ast=node;
		}
		;
declaration_list:
	declaration
		{
			$$.size = $1.size;
		}
		|
	declaration_list declaration
		{

			$$.size = $1.size + $2.size;
		}
		;
declaration:
	type_specifier declarator_list ';'
		{
			$$.size = 0;
			symtab* local_symtab = table_stack.top();
			std::stack <string> varlist_rev;
			while(local_varlist.size()>0){
				string s=local_varlist.top();
				varlist_rev.push(s);
				local_varlist.pop();
				row * r = local_symtab->st[s];
				bool is_pointer = false;
				if(r->type[0]=='*')is_pointer=true;
				r->type = $1.name+r->type;
				if($1.name==curr_struct && is_struct && !is_pointer){
					error(@1,"Cannot declare struct of same type within struct");
				}
				if(is_pointer){
					r->size = 4*r->size;
				}
				else r->size = $1.size*r->size;
				$$.size+=r->size;
				if($1.name=="void" && !is_pointer){
					error(@1,"Cannot declare variable of type "+r->type);
				}
			}
			while(varlist_rev.size()>0){
				string s=varlist_rev.top();
				varlist_rev.pop();
				row * r = local_symtab->st[s];
				if(is_struct){
					r->offset=local_symtab->curr_offset;
					local_symtab->curr_offset +=r->size;
				}
				else {
					local_symtab->curr_offset -=r->size;
					r->offset = local_symtab->curr_offset;
				}
			}
		}
		;
declarator_list:
	declarator
		{
			local_varlist.push($1.name);
			symtab* local_symtab = table_stack.top();
			row * r = local_symtab->st[$1.name];
			$$.size = r->size;
			
		}
		|
	declarator_list ',' declarator
		{

			local_varlist.push($3.name);
			symtab* local_symtab = table_stack.top();
			row * r = local_symtab->st[$3.name];
			$$.size =$1.size+r->size;
		}
		;

printf_call
  : PRINTF '(' STRING_LITERAL ')' ';' {
  }// P1
  | PRINTF '(' STRING_LITERAL ',' expression_list ')' ';' {
  };// P1

%%
void IPL::Parser::error( const location_type &l, const std::string &err_message )
{
   /* std::cerr << "Error: " << err_message << " at " << l << "\n"; */
   std::cout << "Error at line "<<l.begin.line <<": "<<err_message<<"\n";
   exit(1);
}


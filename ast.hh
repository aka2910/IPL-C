#include<vector>
#include<string>
#include<map>
#include<utility>
#include<stack>
#include<iostream>
#include<algorithm>
#include<stdarg.h>
#include<iostream>
#include "symtab.hh"
#include "parser.tab.hh"

struct row;
typedef std::map<std::string,row*> lst;
typedef std::stack<int> si;
extern std::map<std::string,int> glob_str;
extern int jump_index;
extern std::string curr_func;
extern symtab* gst;
extern std::string curr_struct1;
extern int arr_level;


extern void printAst(const char *astname, const char *fmt,...); // fmt is a format string that tells about the type of the arguments->

enum typeExp {
    empty_ast,
    seq_ast,
    assignS_ast,
    return_ast,
    if_ast,
    while_ast,
    for_ast,
    proccall_ast,
    identifier_ast,
    arrayref_ast,
    member_ast,
    arrow_ast,
    op_binary_ast,
    op_unary_ast,
    assignE_ast,
    funcall_ast,
    intconst_ast,
    floatconst_ast,
    stringconst_ast
};

void printAst(const char *astname, const char *fmt,...); // fmt is a format string that tells about the type of the arguments->

class abstract_astnode 
{
public:
    virtual void print(int blanks)=0;
    enum typeExp astnode_type;
    virtual void gencode(lst*a, si*s, int is_proc)=0;
};


class statement_astnode: public abstract_astnode {
public:
    void print(int blanks){}
    void gencode(lst*a, si*s, int is_proc){
        
    }

};

class empty_astnode: public statement_astnode {
public:
    empty_astnode(){
        astnode_type = empty_ast;
    }
    void gencode(lst*a, si*s, int is_proc){}
    void print(int blanks){
        // printAst("empty","");
        std::cout<<"\""<<"empty"<<"\""<<std::endl;
    }
};


class seq_astnode: public statement_astnode {
public:
    seq_astnode(){
        astnode_type = seq_ast;
    }

    std::vector<statement_astnode*> *stmts;
    void gencode(lst*a, si*s, int is_proc){
        arr_level=0;
        for (int i = 0; i < (int)stmts->size(); ++i)
        {
            (*stmts)[i]->gencode(a,s,0);
            arr_level=0;
        }
    }
    void print(int blanks){
        // printAst("seq","l","",stmts);
        std::cout << "{ "<<std::endl;
		std::cout << "\"" << "seq" << "\"" << ": ";
        std::cout << "[" << std::endl;
        for (int i = 0; i < (int)stmts->size(); ++i)
        {
            (*stmts)[i]->print(0);
            if (i < (int)stmts->size() - 1)
                std::cout << "," << std::endl;
            else
                std::cout << std::endl;
        }
        std::cout << std::endl;
        std::cout << "]" << std::endl;
        std::cout<<"}"<<std::endl;

    }

};

class exp_astnode: public abstract_astnode {
public:
    exp_astnode(){

    }
    void print(int blanks){}
    void gencode(lst*a, si*s, int is_proc){}
};

class assignS_astnode: public statement_astnode {
public:
    assignS_astnode(){
        astnode_type = assignS_ast;
    }
    exp_astnode* exp1,* exp2;
    void gencode(lst*a, si*s, int is_proc){
        arr_level=0;
        exp1->gencode(a,s,0);
        arr_level=0;
        exp2->gencode(a,s,0);
        int t=s->top();
        s->pop();
        std::cout<<"\tpopl %edx\n";
        if(t==0) std::cout<<"\tmovl (%edx), %edx\n";
        std::cout<<"\tpopl %eax\n";
        s->pop();
        std::cout<<"\tmovl %edx, (%eax)\n";
    }
    void print(int blanks){
        printAst("assignS","aa", "left",exp1,"right",exp2);
    }

};



class if_astnode: public statement_astnode {
public:
    if_astnode(){
        astnode_type=if_ast;
    }
    exp_astnode* exp;
    statement_astnode *stmt1,*stmt2;
    void print(int blanks){
        printAst("if","aaa","cond",exp,"then",stmt1,"else",stmt2);
    }
    void gencode(lst*a, si*s, int is_proc){
        arr_level=0;
        exp->gencode(a,s,1);
        s->pop();
        std::cout<<"\tpopl %ebx\n";
        std::cout<<"\tcmpl $1, %ebx\n";
        int t1=jump_index;
        std::cout<<"\tjne .L"<<jump_index<<std::endl;
        jump_index++;
        stmt1->gencode(a,s,0);
        std::cout<<"\tjmp .L"<<jump_index<<std::endl; 
        int t2=jump_index;
        jump_index++;
        std::cout<<".L"<<t1<<":"<<std::endl;
        stmt2->gencode(a,s,0);
        std::cout<<".L"<<t2<<":"<<std::endl;
    }

};


class while_astnode: public statement_astnode {
public:
    while_astnode() {
        astnode_type  = while_ast;
    }
    exp_astnode* exp;
    statement_astnode* stmt;
    void gencode(lst*a, si*s, int is_proc){
        int t1=jump_index;
        std::cout<<"\tjmp .L"<<jump_index<<std::endl;
        jump_index++;
        std::cout<<".L"<<jump_index<<":"<<std::endl;
        jump_index++;
        stmt->gencode(a,s,0);
        std::cout<<".L"<<t1<<":"<<std::endl;
        arr_level=0;
        exp->gencode(a,s,1);
        s->pop();
        std::cout<<"\tpopl %ebx\n";
        std::cout<<"\tcmpl $1, %ebx\n";
        std::cout<<"\tje .L"<<t1+1<<std::endl;


    }
    void print(int blanks){
        printAst("while","aa","cond",exp,"stmt",stmt);
    }

};


class for_astnode: public statement_astnode {
public:
    for_astnode(){
        astnode_type=for_ast;
    }
    exp_astnode *exp1,*exp2,*exp3;
    statement_astnode *stmt;
    void gencode(lst*a, si*s, int is_proc){
        arr_level=0;
        exp1->gencode(a,s,0);
        int t1=jump_index;
        std::cout<<"\tjmp .L"<<jump_index<<std::endl;
        jump_index++;
        std::cout<<".L"<<jump_index<<":"<<std::endl;
        jump_index++;
        stmt->gencode(a,s,0);
        arr_level=0;
        exp3->gencode(a,s,0);
        std::cout<<".L"<<t1<<":"<<std::endl;
        arr_level=0;
        exp2->gencode(a,s,1);
        s->pop();
        std::cout<<"\tpopl %ebx\n";
        std::cout<<"\tcmpl $1, %ebx\n";
        std::cout<<"\tje .L"<<t1+1<<std::endl;
    }
    void print(int blanks){
        printAst("for","aaaa","init",exp1,"guard",exp2,"step",exp3,"body",stmt);
    }
};
class identifier_astnode;




class op_binary_astnode: public exp_astnode{
public:
    op_binary_astnode(){
        astnode_type=op_binary_ast;
    }
    exp_astnode *exp1,*exp2;
    std::string str;
    void gencode(lst*a, si*s, int is_proc){
        arr_level=0;
        exp1->gencode(a,s,0);
        bool point = false;
        if(curr_struct1=="int*")point=true;
        arr_level=0;
        exp2->gencode(a,s,0);
        int t=s->top();
        s->pop();
        std::cout<<"\tpopl %ebx\n";
        if(t==0) std::cout<<"\tmovl (%ebx), %ebx\n";
        t=s->top();
        s->pop();
        std::cout<<"\tpop %eax\n";
        if(t==0) std::cout<<"\tmovl (%eax), %eax\n";
        if(str=="PLUS_INT"){        
            if(point){
                std::cout<<"\timul $4, %ebx\n";
            }    
            std::cout<<"\taddl %ebx, %eax\n";
        }
        else if(str=="MINUS_INT"){
            if(point){
                std::cout<<"\timul $4, %ebx\n";
            }  
             std::cout<<"\tsubl %ebx, %eax\n";
        }
        else if(str=="MULT_INT"){
             std::cout<<"\timul %ebx, %eax\n";
        }
        else if(str=="DIV_INT"){
            std::cout<<"\tcltd\n";
            std::cout<<"\tidiv %ebx\n";
        }
        else if(str=="EQ_OP_INT"){
            std::cout<<"\tcmpl %eax, %ebx\n";
            std::cout<<"\tsete %al\n";
            std::cout<<"\tmovzbl %al, %eax\n";
        }
        else if(str=="NE_OP_INT"){
            std::cout<<"\tcmpl %eax, %ebx\n";
            std::cout<<"\tsetne %al\n";
            std::cout<<"\tmovzbl %al, %eax\n";
        }
        else if(str=="GE_OP_INT"){
            std::cout<<"\tcmpl %ebx, %eax\n";
            std::cout<<"\tsetge %al\n";
            std::cout<<"\tmovzbl %al, %eax\n";
        }
        else if(str=="GT_OP_INT"){
            std::cout<<"\tcmpl %ebx, %eax\n";
            std::cout<<"\tsetg %al\n";
            std::cout<<"\tmovzbl %al, %eax\n";
        }
        else if(str=="LT_OP_INT"){
            std::cout<<"\tcmpl %ebx, %eax\n";
            std::cout<<"\tsetl %al\n";
            std::cout<<"\tmovzbl %al, %eax\n";
        }
        else if(str=="LE_OP_INT"){
            std::cout<<"\tcmpl %ebx, %eax\n";
            std::cout<<"\tsetle %al\n";
            std::cout<<"\tmovzbl %al, %eax\n";
        }
        else if(str=="OR_OP"){
            std::cout<<"\tmovl %eax, %edx\n";
            std::cout<<"\tcmpl $0, %ebx\n";
            std::cout<<"\tsetne %al\n";
            std::cout<<"\tmovzbl %al, %ebx\n";
            std::cout<<"\tcmpl $0, %edx\n";
            std::cout<<"\tsetne %al\n";
            std::cout<<"\tmovzbl %al, %eax\n";
            std::cout<<"\tor %ebx, %eax\n";
        }
        else if(str=="AND_OP"){
            std::cout<<"\tmovl %eax, %edx\n";
            std::cout<<"\tcmpl $0, %ebx\n";
            std::cout<<"\tsetne %al\n";
            std::cout<<"\tmovzbl %al, %ebx\n";
            std::cout<<"\tcmpl $0, %edx\n";
            std::cout<<"\tsetne %al\n";
            std::cout<<"\tmovzbl %al, %eax\n";
            std::cout<<"\tand %ebx, %eax\n";
        }
        std::cout<<"\tpushl %eax\n";
        s->push(1);
    }
    void print(int blanks){
        printAst("op_binary","saa","op",str.c_str(),"left",exp1,"right",exp2);
    }
};


class op_unary_astnode: public exp_astnode{
public:
    op_unary_astnode(){
        astnode_type=op_unary_ast;
    }
    std::string str;
    exp_astnode *exp;
    void gencode(lst*a, si*s, int is_proc){
        arr_level=0;
        exp->gencode(a,s,0);
        std::cout<<"\tpopl %ebx\n";
        int t=s->top();
        s->pop();
        if(str=="UMINUS"){
            if(t==0) std::cout<<"\tmovl (%ebx), %ebx\n";
            std::cout<<"\tnegl %ebx\n";
             std::cout<<"\tpushl %ebx\n";
        }
        else if(str=="NOT"){
            if(t==0) std::cout<<"\tmovl (%ebx), %ebx\n";
            std::cout<<"\tcmpl $0, %ebx\n";
            std::cout<<"\tsete %al\n";
            std::cout<<"\tmovzbl %al, %eax\n";
            std::cout<<"\tpushl %eax\n";
        }
        else if(str=="PP"){
            std::cout<<"\tmovl (%ebx), %eax\n";
            std::cout<<"\taddl $1, %eax\n";
            std::cout<<"\tpushl (%ebx)\n";

        }
        else if(str=="ADDRESS"){
            std::cout<<"\tpushl %ebx\n";
        }
        else if(str=="DEREF"){
            if(is_proc==1)std::cout<<"\tmovl (%ebx), %ebx\n";

            if(t==0)std::cout<<"\tpushl (%ebx)\n";
            else std::cout<<"\tpushl %ebx\n";
        }
        s->push(1);   
        if(str=="DEREF"){
            s->pop();
            s->push(0);
        }
    }
    void print(int blanks){
        printAst("op_unary","sa","op",str.c_str(),"child",exp);
    }
};

class assignE_astnode: public exp_astnode{
public:
    assignE_astnode(){
        astnode_type=assignE_ast;
    }
    exp_astnode *exp1,*exp2;
    void gencode(lst*a, si*s, int is_proc){
        arr_level=0;
        exp1->gencode(a,s,0);
        arr_level=0;
        exp2->gencode(a,s,0);
        int t=s->top();
        s->pop();
        std::cout<<"\tpopl %edx\n";
        if(t==0) std::cout<<"\tmovl (%edx), %edx\n";
        std::cout<<"\tpopl %eax\n";
        t=s->top();
        s->pop();
        std::cout<<"\tmovl %edx, (%eax)\n";
    }
    void print(int blanks){
        printAst("assignE","aa","left",exp1,"right",exp2);
    }
};



class intconst_astnode: public exp_astnode{
public:
    intconst_astnode(){
        astnode_type=intconst_ast;
    }
    std::string num;
    void gencode(lst*a, si*s, int is_proc){
        s->push(1);
        std::cout<<"\tpushl $"<<num<<std::endl;
    }
    void print(int blanks){
        printAst("intconst","i","",std::stoi(num));
    }
};

class floatconst_astnode: public exp_astnode{
public:
    floatconst_astnode(){
        astnode_type=floatconst_ast;
    }
    std::string num;
    void gencode(lst*a, si*s, int is_proc){}
    void print(int blanks){
        printAst("floatconst","f","",std::stof(num));
    }
};

class stringconst_astnode: public exp_astnode{
public:
    stringconst_astnode(){
        astnode_type=stringconst_ast;
    }
    std::string str;
    void gencode(lst*a, si*s, int is_proc){
        int index=glob_str[str];
        s->push(1);
        std::cout<<"\tpushl $.LC"<<index<<std::endl;
    }
    void print(int blanks){
        // printAst("stringconst","s","",str.c_str());
        std::cout << "{ "<<std::endl;
		std::cout << "\"" << "stringconst" << "\"" << ": ";
		std::cout << str << std::endl;
        std::cout<<"}"<<std::endl;
    }
};

class ref_astnode: public exp_astnode {
public:
    void gencode(lst*a, si*s, int is_proc){}
    void print(int blanks){}
};

class identifier_astnode : public ref_astnode {
public:
    identifier_astnode(){
        astnode_type=identifier_ast;
    }
    std::string str;
    void gencode(lst*a, si*s, int is_proc){
        curr_struct1 = (*a)[str]->type;
        if(is_proc<=1){
            int off=(*a)[str]->offset;
            std::cout<<"\tmovl %ebp, %eax\n";
            if(off>0){
                std::cout<<"\taddl $"<<off<<", %eax"<<std::endl;
            }
            else if (off<0){

                std::cout<<"\tsubl $"<<-off<<", %eax"<<std::endl;
                
            }
            if(curr_struct1=="int"){
                if(is_proc==0)std::cout<<"\tpushl %eax\n";
                else if(is_proc==1)std::cout<<"\tpushl (%eax)\n";
                if(is_proc==0)s->push(0);
                else if(is_proc==1) s->push(1);
            }
            else if(is_proc==0){
                
                if((*a)[str]->global=="param" && (curr_struct1.find('[')!=std::string::npos ) ){std::cout<<"\tmovl (%eax), %eax\n";
                s->push(1);}
                else s->push(0);
                // s->push(0);
                std::cout<<"\tpushl %eax\n";

            }
            else if(curr_struct1.substr(0,3)!="int" && curr_struct1.find('[')==std::string::npos ){
                int size=(*a)[str]->size;
                std::cout<<"\taddl $"<<size<<", %eax"<<std::endl;
                for(int i=0;i<size/4;i++){
                    std::cout<<"\tsubl $4, %eax\n";
                    std::cout<<"\tpushl (%eax)\n";
                }
                s->push(1);
            }
            else {
                if(curr_struct1.find('[')!=std::string::npos)std::cout<<"\tpushl %eax\n";
                else std::cout<<"\tpushl (%eax)\n";
                s->push(0);
            }
        }
        else {
            std::cout<<"\tpopl %eax\n";
            s->pop();
            int off=(*a)[str]->offset;
            std::string type = (*a)[str]->type;
            std::cout<<"\taddl $"<<off<<", %eax"<<std::endl;
            if(is_proc==2){
                std::cout<<"\tpushl %eax\n";
                s->push(0);
            }
            else if(is_proc==3){
                if(type=="int"){
                    std::cout<<"\tpushl (%eax)\n";
                    s->push(1);
                }
                else{
                    std::cout<<"\tpushl %eax\n";
                    s->push(0);
                }
            }

        }
    }
    void print(int blanks){
        // printAst("identifier","s","",str.c_str());
        std::cout << "{ "<<std::endl;
		std::cout << "\"" << "identifier" << "\"" << ": ";
		std::cout << "\"" << str << "\""<<std::endl;
        std::cout<<"}"<<std::endl;
    }
};

class arrayref_astnode : public ref_astnode {
public:
    arrayref_astnode(){
        astnode_type=arrayref_ast;
    }
    exp_astnode *exp1,*exp2;
    void gencode(lst*a, si*s, int is_proc){
        int temp= arr_level;
        arr_level=0;
        exp2->gencode(a,s,0);
        arr_level=temp;
        exp1->gencode(a,s,0);
        arr_level=arr_level+1;
        // std::cout<<"\tArray level "<<arr_level<<std::endl;
        std::cout<<"\tpopl %eax\n";
        std::cout<<"\tpopl %ebx\n";
         int t=s->top();
        s->pop();
        if(t==0 && (curr_struct1.find('*')!=std::string::npos))std::cout<<"\tmovl (%eax), %eax\n";
        t=s->top();
        s->pop();
        if(t==0)std::cout<<"\tmovl (%ebx), %ebx\n";
        
        std::string type = curr_struct1;
        int initial=0;
        if(type.substr(0,3)=="int")initial=4;
        else{
            size_t f1=type.find('[');
            if(f1!=std::string::npos){
                initial=(gst->st)[type.substr(0,f1)]->size;
            }
            else {
                f1=type.find('*');
                initial=(gst->st)[type.substr(0,f1)]->size;
            }
        }
        int initial_temp=initial;
        for(int i=0;i<arr_level;i++){
            size_t f1=type.find('[');
            if(f1!=std::string::npos){
                type=type.substr(type.find(']')+1);
            }
        }
        size_t f2=type.find('[');
        while(f2!=std::string::npos){
            std::string curr_size = type.substr(f2+1,type.find(']'));

            initial*=stoi(curr_size);
            type=type.substr(type.find(']')+1);
            f2=type.find('[');
        }
        std::cout<<"\timul $"<<initial<<", %ebx\n";
        
        std::cout<<"\taddl %ebx, %eax\n";
        if(is_proc==0 || initial_temp!=initial)std::cout<<"\tpushl %eax\n";
        else std::cout<<"\tpushl (%eax)\n";
        s->push(0);
    }
    void print(int blanks){
        printAst("arrayref","aa","array",exp1,"index",exp2);
    }
};

class member_astnode : public ref_astnode {
public:
    member_astnode(){
        astnode_type=member_ast;
    }
    exp_astnode *exp;
    identifier_astnode *id;
    void gencode(lst*a, si*s, int is_proc){
        arr_level=0;
        exp->gencode(a,s,0);
        id->gencode(&(gst->st[curr_struct1]->next->st),s,is_proc+2);

    }
    void print(int blanks){
        printAst("member","aa","struct",exp,"field",id);
    }
};

class arrow_astnode : public ref_astnode {
public:
    arrow_astnode(){
        astnode_type=arrow_ast;
    }
    exp_astnode *exp;
    identifier_astnode *id;
    void gencode(lst*a, si*s, int is_proc){
        arr_level=0;
        exp->gencode(a,s,0);
        curr_struct1=curr_struct1.substr(0,curr_struct1.size()-1);
        std::cout<<"\tpopl %eax\n\t pushl (%eax)\n";
        id->gencode(&(gst->st[curr_struct1]->next->st),s,is_proc+2);
    }
    void print(int blanks){
        printAst("arrow","aa","pointer",exp,"field",id);
    }
};

class proccall_astnode: public statement_astnode {
public:
    proccall_astnode(){
        astnode_type=proccall_ast;
    }
    identifier_astnode * name;
    std::vector<exp_astnode*> *exps;
    // void gencode(lst*a, si*s, int is_proc){
    //     // for(int i=(*exps).size()-1;i>=0;i--){
    //     //     (*exps)[i]->gencode(a,s,1);
    //     // }
    //     // std::cout<<"\tcall "<<name->str<<std::endl;
    //     // std::cout<<"\taddl $"<<4*(*exps).size()<<", %esp\n";

    //     if(name->str=="printf"){
    //         for(int i=(*exps).size()-1;i>=0;i--){
    //             (*exps)[i]->gencode(a,s,1);
    //         }
    //     }
    //     else{ 
    //         if(gst->st[name->str]->type=="int") std::cout<<"\tsubl $4, %esp\n";
    //         else if(gst->st[name->str]->type!="void"){
    //             int new_size = gst->st[gst->st[name->str]->type]->size;
    //             std::cout<<"\tsubl $"<<new_size<<", %esp\n";
    //         }
    //         for(int i=0;i<=(*exps).size()-1;i++){
    //             (*exps)[i]->gencode(a,s,1);
    //         }
    //     }        
    //     std::cout<<"\tcall "<<name->str<<std::endl;
    //     // std::cout<<"\taddl $8, %esp\n";
    //     std::cout<<"\taddl $"<<4*(*exps).size()<<", %esp\n";

    // }
    void print(int blanks){
        printAst("proccall","al","fname",name,"params",exps);
    }
    void gencode(lst*a, si*s, int is_proc){
        if(name->str=="printf"){
            for(int i=(*exps).size()-1;i>=0;i--){
                arr_level=0;
                (*exps)[i]->gencode(a,s,1);
            }
            std::cout<<"\tcall "<<name->str<<std::endl;
        // std::cout<<"\taddl $8, %esp\n";
            std::cout<<"\taddl $"<<4*(*exps).size()<<", %esp\n";
        }
        else{ 
            if(gst->st[name->str]->type=="int") std::cout<<"\tsubl $4, %esp\n";
            else if(gst->st[name->str]->type!="void"){
                int new_size = gst->st[gst->st[name->str]->type]->size;
                std::cout<<"\tsubl $"<<new_size<<", %esp\n";
            }
            for(int i=0;i<=(*exps).size()-1;i++){
                arr_level=0;
                (*exps)[i]->gencode(a,s,1);
            }
            std::cout<<"\tcall "<<name->str<<std::endl;
            if(gst->st[name->str]->type=="int")std::cout<<"\taddl $"<<4*(*exps).size()<<", %esp\n";
            else if(gst->st[name->str]->type!="void"){
                int param_size=0;
                for(auto i: gst->st[name->str]->next->st){
                    if(i.second->global=="param"){
                    param_size+=i.second->size;
                    }
                }
                std::cout<<"\taddl $"<<param_size<<", %esp\n";  
            }
        }        
        
    }

};


class funcall_astnode: public exp_astnode{
public:
    funcall_astnode(){
        astnode_type=funcall_ast;
    }
    std::vector<exp_astnode*> *exps;
    identifier_astnode * name;
    void print(int blanks){
        printAst("funcall","al","fname",name,"params",exps);
    }
    void gencode(lst*a, si*s, int is_proc){
        if(name->str=="printf"){
            for(int i=(*exps).size()-1;i>=0;i--){
                arr_level=0;
                (*exps)[i]->gencode(a,s,1);
            }
            std::cout<<"\tcall "<<name->str<<std::endl;
        // std::cout<<"\taddl $8, %esp\n";
            std::cout<<"\taddl $"<<4*(*exps).size()<<", %esp\n";
        }
        else{ 
            if(gst->st[name->str]->type=="int") std::cout<<"\tsubl $4, %esp\n";
            else if(gst->st[name->str]->type!="void"){
                int new_size = gst->st[gst->st[name->str]->type]->size;
                std::cout<<"\tsubl $"<<new_size<<", %esp\n";
            }
            for(int i=0;i<=(*exps).size()-1;i++){
                arr_level=0;
                (*exps)[i]->gencode(a,s,1);
            }
            std::cout<<"\tcall "<<name->str<<std::endl;
            if(gst->st[name->str]->type=="int")std::cout<<"\taddl $"<<4*(*exps).size()<<", %esp\n";
            else if(gst->st[name->str]->type!="void"){
                int param_size=0;
                for(auto i: gst->st[name->str]->next->st){
                    if(i.second->global=="param"){
                    param_size+=i.second->size;
                    }
                }
                std::cout<<"\taddl $"<<param_size<<", %esp\n";  
            }

        }        
        
    }
};

class return_astnode: public statement_astnode {
public:
    return_astnode(){
        astnode_type= return_ast;
    }
    exp_astnode* exp;
    void gencode(lst*a, si*s, int is_proc){
        std::string name = curr_func;
        arr_level=0;
        exp->gencode(a,s,1);
        int size_loc=0;
        for(auto i : *a){
            if(i.second->global=="param")size_loc+=i.second->size;
        }
        if(gst->st[name]->type!="void"){
            s->pop();
            std::cout<<"\tpopl %eax\n";
        }
        if(curr_func!="main"){
            if(gst->st[name]->type=="int")std::cout<<"\tmovl %eax, "<<8+size_loc<<"(%ebp)\n";
            else if(gst->st[name]->type!="void"){
                int new_size = gst->st[gst->st[name]->type]->size;
                for(int i=0;i<new_size/4-1;i++){
                    std::cout<<"\tmovl %eax, "<<8+size_loc<<"(%ebp)\n";
                    size_loc+=4;
                    std::cout<<"\tpopl %eax\n";
                }
                std::cout<<"\tmovl %eax, "<<8+size_loc<<"(%ebp)\n";
            } 
        }
        std::cout<<"\t leave\n\tret\n";
 

    }
    void print(int blanks){
        // printAst("return","a","",exp);
        std::cout << "{ "<<std::endl;
		std::cout << "\"" << "return" << "\"" << ": "<<std::endl;
        ((abstract_astnode*)exp)->print(0);
        std::cout<<"}"<<std::endl;
    }

};


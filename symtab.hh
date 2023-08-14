
struct row;
struct symtab;
class abstract_astnode;


struct row {
    std::string name;
    std::string varfunc;
    std::string global;
    int size;
    int offset;
    std::string type;
    struct symtab* next;
};


struct symtab{
    std::map<std::string,row*> st;
    int curr_offset;
    int param_offset;
    void printgst(){
        std::cout<<"[";
        for (auto it = st.begin(); it != st.end(); ++it){
            row* entry = it->second;
            std::cout<<"[\t";
            std::cout<<"\t\""<<entry->name<<"\",\t";
            std::cout<<"\t\""<<entry->varfunc<<"\",\t";
            std::cout<<"\t\""<<entry->global<<"\",\t";
            std::cout<<"\t"<<entry->size<<",\t";
            if(entry->varfunc!="struct")
            std::cout<<"\t"<<entry->offset<<",\t";
            else 
            std::cout<<"\t\""<<"-"<<"\",\t";
            std::cout<<"\t\""<<entry->type<<"\""<<std::endl;
            std::cout<<"]"; 
            if (next(it,1) != st.end()) 
                std::cout<<","<<std::endl;
            else
                std::cout<<std::endl;      
            
        }
        std::cout<<"]"<<std::endl;

    }
    void print(){
        std::cout<<"["<<std::endl;
        for (auto it = st.begin(); it != st.end(); ++it){
            row* entry = it->second;
            std::cout<<"[\t";
            std::cout<<"\t\""<<entry->name<<"\",\t";
            std::cout<<"\t\""<<entry->varfunc<<"\",\t";
            std::cout<<"\t\""<<entry->global<<"\",\t";
            std::cout<<"\t"<<entry->size<<",\t";
            if(entry->varfunc!="struct")
            std::cout<<"\t"<<entry->offset<<",\t";
            else 
            std::cout<<"\t\""<<"-"<<"\",\t";
            std::cout<<"\t\""<<entry->type<<"\""<<std::endl;
            std::cout<<"]"<<std::endl; 
            if (next(it,1) != st.end()) 
                std::cout<<","<<std::endl;
            else
                std::cout<<std::endl;      
            
        }
        std::cout<<"]"<<std::endl;
    }
};

struct nterm_datatype {
    std::string name;
    std::string type;
    abstract_astnode* ast;
    int size;
    struct symtab* st;
    bool lvalue;

    bool is_int(){
        if(type.size()>=3){
            if(type.substr(0,3)=="int"){
                return true;
            }
        }
        return false;
    }

    bool is_float(){
        if(type.size()>=5){
            if(type.substr(0,5)=="float"){
                return true;
            }
        }
        return false;
    }

    bool is_void(){
        if(type.size()>=4){
            if(type.substr(0,4)=="void"){
                return true;
            }
        }
        return false;
    }

    bool is_pointer(){
        if(type.find('*')==std::string::npos){
            if(type.find('[')==std::string::npos){
                return false;
            }
        }
        return true;
    }

    bool is_array(){
        if(type.find('[')==std::string::npos){
                return false;
        }
        return true;
    }
};


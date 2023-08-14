#include <cstring>
#include <cstddef>
#include <istream>
#include <iostream>
#include <fstream>
#include <vector>
#include <stack>

#include "scanner.hh"
#include "parser.tab.hh"

using namespace std;

extern symtab* gst;
extern string curr_func;
vector<pair<string,row*>> gstfun, gststruct; 
string filename;
extern std::map<string,abstract_astnode*> ast;
extern std::map<string,int> glob_str;
// std::map<std::string, datatype> predefined {
//             {"printf", createtype(VOID_TYPE)},
//             {"scanf", createtype(VOID_TYPE)},
//             {"mod", createtype(INT_TYPE)}
//         };
int main(int argc, char **argv)
{
	using namespace std;
	fstream in_file, out_file;
	

	in_file.open(argv[1], ios::in);

	IPL::Scanner scanner(in_file);

	IPL::Parser parser(scanner);

#ifdef YYDEBUG
	parser.set_debug_level(1);
#endif
parser.parse();
// create gstfun with function entries only

for (const auto &entry : gst->st)
{
	if (entry.second->varfunc == "fun")
	gstfun.push_back({entry.first, entry.second});
}
// create gststruct with struct entries only

for (const auto &entry : gst->st)
{
	if (entry.second->varfunc == "struct")
	gststruct.push_back({entry.first, entry.second});
}

cout<<"\t.section\t.rodata"<<endl;
for(auto i:glob_str){
	cout<<".LC"<<i.second<<":\n";
	cout<<"\t.string "<<i.first<<endl;
}

cout<<"\t.text\n";
// start the JSON printing


// ****************************************************


// cout << "{\"globalST\": " << endl;
// gst->printgst();
// cout << "," << endl;

// cout << "  \"structs\": [" << endl;
// for (auto it = gststruct.begin(); it != gststruct.end(); ++it)

// {   cout << "{" << endl;
// 	cout << "\"name\": " << "\"" << it->first << "\"," << endl;
// 	cout << "\"localST\": " << endl;
// 	it->second->next->print();
// 	cout << "}" << endl;
// 	if (next(it,1) != gststruct.end()) 
// 	cout << "," << endl;
// }
// cout << "]," << endl;
// cout << "  \"functions\": [" << endl;

// for (auto it = gstfun.begin(); it != gstfun.end(); ++it)

// {
// 	cout << "{" << endl;
// 	cout << "\"name\": " << "\"" << it->first << "\"," << endl;
// 	cout << "\"localST\": " << endl;
// 	it->second->next->print();
// 	cout << "," << endl;
// 	cout << "\"ast\": " << endl;
// 	ast[it->first]->print(0);
// 	cout << "}" << endl;
// 	if (next(it,1) != gstfun.end()) cout << "," << endl;
	
// }
// 	cout << "]" << endl;
// 	cout << "}" << endl;

// 	fclose(stdout);

std::stack<int> ident_stack;
for (auto it = gstfun.begin(); it != gstfun.end(); ++it)
{
	string name = it->first;
	curr_func=name;
	cout<<"\t.globl "<<name<<endl;
	cout<<"\t.type "<<name<<", @function"<<endl;
	cout<<name<<":\n";
	cout<<"\tpushl %ebp\n \tmovl %esp, %ebp\n";
	int size_loc=0;
	for(auto i: gst->st[name]->next->st)if(i.second->global=="local")size_loc+=i.second->size;
	if(size_loc>0){
		cout<<"\tsubl	$"<<size_loc<<", %esp\n";
	}
	ast[it->first]->gencode(&(gst->st[name]->next->st),&ident_stack,0);
	if(gst->st[name]->type=="void"){
		std::cout<<"\t leave\n\tret\n";
	}
}
}
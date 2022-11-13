#include<bits/stdc++.h>
using namespace std;
typedef long long ll;
#include <time.h>

int main(){
    string s;
    srand(time(0));
    ofstream f("instructions.txt");
    for(int i=0;i<100000;i++){
        s.clear();
        for(int j=0;j<50;j++){
            ll k=rand()%2;
            if(k)s.push_back('1');
            else
            s.push_back('0');
        }
        f<<s<<"\n";
    }
}

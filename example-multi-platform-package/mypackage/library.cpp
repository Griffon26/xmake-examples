#include <iostream>

void libfunc()
{
#ifdef _MSC_VER
    std::cout << "Hello from MSVC\n";
#else
    std::cout << "Hello from gcc\n";
#endif
}

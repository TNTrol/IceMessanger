#include "test.h"
#include <iostream>

void print_hello()
{
    std::cout << "Hello\n";
}

// MessagerImpl::MessagerImpl()
// {
// }

// MessagerImpl::~MessagerImpl()
// {
// }

void MessangerImpl::say(const std::string &s, const Ice::Current &)
{
    std::cout << s << " Server Hello\n";
}
#include "server.h"
#include <iostream>

void MessangerImpl::say(const std::string& s, const Ice::Current &)
{
    std::cout << "Server: " << s << std::endl;
}
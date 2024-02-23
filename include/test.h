#pragma once
#include "messanger/hello.h"
#include <string>

void print_hello();

class MessangerImpl : public Messanger::ICommunacation
{
public:
    void say(const std::string& s, const Ice::Current& = Ice::Current()) override;
};
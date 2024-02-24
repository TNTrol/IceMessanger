#pragma once
#include "messanger/messanger.h"
#include <string>

class MessangerImpl : public Messanger::ICommunacation
{
public:
    void say(const std::string& s, const Ice::Current& = Ice::Current()) override;
};
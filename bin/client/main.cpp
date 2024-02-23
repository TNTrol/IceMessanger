#include "test.h"
#include <Ice/Ice.h>

int main()
{
    Ice::PropertiesPtr iceProperies = Ice::createProperties();
        Ice::InitializationData iceInitData;
        iceInitData.properties = iceProperies;
        Ice::CommunicatorPtr ic;
    try
    {
        ic = Ice::initialize(iceInitData);
        auto base = ic->stringToProxy("Messanger: default -p 10002 -t 2000");
        auto messager = Ice::checkedCast<Messanger::ICommunacationPrx>(base);
        messager->say("From Client");
        
    }
    catch (const Ice::Exception &e)
    {
        std::cerr << e << std::endl;
    }
    catch (const char *msg)
    {
        std::cerr << msg << std::endl;
    }
    if (ic) {
        ic->destroy();
    }
    return 0;
}
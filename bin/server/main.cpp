#include "server.h"
#include <Ice/Ice.h>
#include <memory>

int main()
{
    int status = 0;
    Ice::CommunicatorPtr ic;
    try {
        ic = Ice::initialize();
        Ice::ObjectAdapterPtr adapter =
            ic->createObjectAdapterWithEndpoints("Messanger", "default -p 10002");
        auto servant = std::make_shared<MessangerImpl>();
        adapter->add(servant.get(), Ice::stringToIdentity("Messanger"));
        adapter->activate();
        ic->waitForShutdown();
    } catch (const Ice::Exception& e) {
        std::cerr << e << std::endl;
        status = 1;
    } catch (const char* msg) {
        std::cerr << msg << std::endl;
        status = 1;
    }
    if (ic) {
        try {
            ic->destroy();
        } catch (const Ice::Exception& e) {
            std::cerr << e << std::endl;
            status = 1;
        }
    }
    return status;
}
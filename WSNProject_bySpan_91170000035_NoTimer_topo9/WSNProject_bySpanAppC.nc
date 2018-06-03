#include "WSNProject_bySpan.h"

configuration WSNProject_bySpanAppC {
}
implementation {
	components MainC;
	components LedsC;
	components WSNProject_bySpanC as App;
	components new TimerMilliC() as Timer0;
	components ActiveMessageC;
	components new AMSenderC(AM_BLINKTORADIO);
	components new AMReceiverC(AM_BLINKTORADIO);
	components RandomC;
	
	
	App.Boot -> MainC;
	App.Timer0 -> Timer0;
	App.Packet -> AMSenderC;
	App.AMPacket -> AMSenderC;
	App.AMControl -> ActiveMessageC;
	App.AMSend -> AMSenderC;
	App.Receive -> AMReceiverC;
	App.PacketAcknowledgements -> ActiveMessageC;
	App.Random -> RandomC;
}

#include "WSNProject_bySpan.h"

module WSNProject_bySpanC {

	uses{
		interface Boot;
		interface Timer<TMilli> as Timer0;
		interface Packet;
		interface AMPacket;
		interface AMSend;
		interface Receive;
		interface SplitControl as AMControl;
		interface PacketAcknowledgements;
		interface Random;
	}
}

implementation {
	am_addr_t neighborNodes[ MAX_ARRAY_SIZE ] = {};
	am_addr_t whiteNodes[ MAX_ARRAY_SIZE ] = {};
	am_addr_t grayNodes[ MAX_ARRAY_SIZE ] = {};
	am_addr_t blackNodes[ MAX_ARRAY_SIZE ] = {};
	am_addr_t spans[ MAX_ARRAY_SIZE ] = {};
	
	uint8_t currentState;
	uint8_t myColor = WHITE;
	message_t pkt;
	
	uint8_t generateRandom(uint32_t upperBound){
		uint16_t rnd = call Random.rand16();		
		return (rnd % upperBound) + 1;
	}
	
	/*
	* Function to count number of element in integer array
	*/
	uint8_t sizeofArray(am_addr_t* array){
		uint8_t size = 0;
		while(array[ size ]){
			size++; 
		}
		
		return size;
	}
	
	char* messageTypeToString(uint8_t type){
		return (type == GRAY ? "GRAY" : (type == BLACK ? "BLACK" : "WHITE") );
	}
	
	void sendUnicastMessage(uint8_t messageType, am_addr_t destination){
		
		MDS_message* btrpkt = (MDS_message*)(call Packet.getPayload(&pkt, sizeof(MDS_message)));
		if (btrpkt == NULL) {
			return;
		}
		btrpkt->_type = messageType;
		
		call PacketAcknowledgements.requestAck(&pkt);
		
		if (call AMSend.send(destination, &pkt, sizeof(MDS_message)) == SUCCESS) {
			dbg("sendUnicastMessage", "[ %s ] -- %s packet: Mote-(%d) --> Mote-(%d). \n", sim_time_string(), messageTypeToString(messageType), TOS_NODE_ID, destination);
		}
	}

	void sendBroadcastMessage(uint8_t type){
	
		MDS_message* btrpkt = (MDS_message*)(call Packet.getPayload(&pkt, sizeof(MDS_message)));
		
		if (btrpkt == NULL) {
			return;
		}
		
		btrpkt->_type = type;
		
		if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(MDS_message)) == SUCCESS) {
			
			dbg("sendBroadcastMessage", "[ %s ] -- sendBroadcastMessage(): %s packet from Mote-(%d) --> All\n", sim_time_string(), messageTypeToString(type), TOS_NODE_ID);
		}else{
			dbgerror("Error", "[ %s ] -- sendBroadcastMessage(): %s packet from Mote-(%d) --> All has failed\n", sim_time_string(), messageTypeToString(type), TOS_NODE_ID);
		}
		
	}	  

	void printArray(char* arrName, am_addr_t arr[]){
		uint8_t i, size = sizeofArray(arr);
		
		dbg("printArray","*** Mote-(%d) - %s: [ ", TOS_NODE_ID, arrName);
		for(i = 0; i < size; i++){
			printf("%d; ", arr[ i ] );
		}
		printf("] \n \n");
	}
	
	void printFullArray(char* arrName, am_addr_t arr[]){
		uint8_t i, size = MAX_ARRAY_SIZE;
		
		dbg("printArray","*** Mote-(%d) - %s: [ ", TOS_NODE_ID, arrName);
		for(i = 0; i < size; i++){
			printf("%d; ", arr[ i ] );
		}
		printf("] \n \n");
	}
	
	/* 
	* Function to sort an array by using insertion sort
	* Note that node ids are assumed as integer type
	*/
	void insertionSort(am_addr_t arr[]){
		int8_t i, j; 
		uint8_t size = sizeofArray(arr);
		am_addr_t key;
		
		for (i = 1; i < size; i++){
			key = arr[ i ];
			j = i - 1;
		
			/* Move elements of arr[0..i-1], that are
				greater than key, to one position ahead
				of their current position */
			while (j >= 0 && arr[ j ] > key)
			{
				arr[ j+1 ] = arr[ j ];
				j = j - 1;
			}	
			arr[ j+1 ] = key;
		}
	}
	
	void deleteElement(am_addr_t arr[], am_addr_t val){
		int8_t position;
		uint8_t size = sizeofArray(arr);
		
		for(position = 0; position < size; position++){
			
			if(arr[ position ] == val){
				break;
			}
		}
		
		if( 0 <= position && position < MAX_ARRAY_SIZE){
			
			for(position = position; position < size; position++){
				arr[ position ] = arr[ position + 1 ];
			}
			arr[ position + 1 ] = MY_NULL; 
		}else{
			dbgerror("Error", "[ %s ] -- deleteElement(): Array does not contain %d value. \n", sim_time_string(), val);
		}
	}
	
	void addElement(am_addr_t arr[], am_addr_t val){
		int8_t position = 0, i;
		uint8_t size = sizeofArray(arr);
		am_addr_t temp;
		
		if(size < MAX_ARRAY_SIZE){
			while(arr[ position ] && arr[ position ] < val){
				position++;
			}
			
			if(position < size){
				temp = arr[ position ];
				
				for(i = size; i > position; i--){
					arr[ i+1 ] = arr[ i ];
				}
				arr[ position+1 ] = temp;
				arr[ position ] = val;
			}else if( position == size){
				arr[ position ] = val;
			}else{
				dbgerror("Error", "[ %s ] -- addElement(): Not possible to add element %d due to case 1.!!! \n", sim_time_string(), val);
			}
		}else{
			dbgerror("Error", "[ %s ] -- addElement(): Not possible to add element %d due to case 2.!!! \n", sim_time_string(), val);
		}
	}
	
	uint8_t indexOf(am_addr_t nodeid){
		return nodeid - 1;
	}
	
	void decreaseSpans(){
		uint8_t i;
		for(i = 0; i < MAX_ARRAY_SIZE; i++){
			if(spans[ i ] > 0){
				spans[ i ]--;
			}
		}
	}
	
	void setZeroSpan(am_addr_t nodeid){
		spans[ indexOf(nodeid) ] = 0;
	}
	
	void decreaseMySpan(){
		if(spans[ indexOf(TOS_NODE_ID) ] > 0){
			spans[ indexOf(TOS_NODE_ID) ]--;
		}
	}
	
	
	/*
	* Function to find out if node has greatest span count
	* If 2 or more nodes have the same span count, select a node that has max id.
	*/
	uint8_t findIndexOfMaximumSpan(am_addr_t arr[]){
		int8_t i;
		uint8_t size = MAX_ARRAY_SIZE;
		am_addr_t maxIdIndex = 0;
		
		for(i = 1; i < size; i++){
			if(spans[ i ] >= spans[ maxIdIndex ]){
				maxIdIndex = i;
			}
		}
		
		return maxIdIndex;
	}
	
	void checkIfBlack(){
		uint8_t maxSpanIndex;

		if(myColor == WHITE){
			currentState = STATE_CHECK;
			maxSpanIndex = findIndexOfMaximumSpan(whiteNodes);
			
			if(maxSpanIndex == indexOf(TOS_NODE_ID) ){
				
				myColor = BLACK;
					
				sendBroadcastMessage(BLACK);
					
				currentState = STATE_BLACK;
					
				dbg("printColor","\n\n ************* Mote-(%d) - BLACK ********* \n\n", TOS_NODE_ID);
				
				decreaseSpans();
			}else{
				currentState = STATE_IDLE;
			}
		}
	}
	
	
	task void printStep(){
		uint8_t i;
		uint8_t whiteSize = sizeofArray(whiteNodes);
		uint8_t graySize = sizeofArray(grayNodes);
		uint8_t blackSize = sizeofArray(blackNodes);
		char whites[ MAX_ARRAY_SIZE ] = {};
		char grays[ MAX_ARRAY_SIZE ] = {};
		char blacks[ MAX_ARRAY_SIZE ] = {};
		
		for(i = 0; i < whiteSize; i++){
			char current[ MAX_ARRAY_SIZE ] = {};
			snprintf(current, sizeof(current), "%d%s", whiteNodes[ i ], (i + 1 < whiteSize ? ", " : ""));
			strcat(whites, current);
		}
		
		for(i = 0; i < graySize; i++){
			char current[ MAX_ARRAY_SIZE ] = {};
			snprintf(current, sizeof(current), "%d%s", grayNodes[ i ], (i + 1 < graySize ? ", " : ""));
			strcat(grays, current);
		}
		
		for(i = 0; i < blackSize; i++){
			char current[ MAX_ARRAY_SIZE ] = {};
			snprintf(current, sizeof(current), "%d%s", blackNodes[ i ], (i + 1 < blackSize ? ", " : ""));
			strcat(blacks, current);
		}
				
		dbg("printStep", "[ %s ] -- printStep(): me: %s, whiteNodes:[ %s ], grayNodes:[ %s ], blackNodes:[ %s ]. \n", sim_time_string(), messageTypeToString(myColor), whites, grays, blacks);
	}
	
	bool isNodeGray(am_addr_t id){
		uint8_t i, graySize = sizeofArray(grayNodes);
		
		for(i = 0; i < graySize; i++){
			if(grayNodes[ i ] == id){
				// If node is in grayNodes, then return TRUE
				return TRUE;
			}
		}
		
		return FALSE;
	}
	
	bool isNodeBlack(am_addr_t id){
		uint8_t i, blackSize = sizeofArray(blackNodes);
		
		for(i = 0; i < blackSize; i++){
			if(blackNodes[ i ] == id){
				// If node is in blackNodes, then return TRUE
				return TRUE;
			}
		}
		
		return FALSE;
	}

	
	/**************** Boot *********************/
	event void Boot.booted() {	
		
		uint8_t i;
		uint8_t size = sizeofArray(topology9[ indexOf(TOS_NODE_ID) ]);
		
		spans[ indexOf(TOS_NODE_ID) ] = size;
		
		for(i = 0; i < size; i++){
			neighborNodes[ i ] = topology9[ indexOf(TOS_NODE_ID) ][ i ];
		}
		
		insertionSort(neighborNodes);
		
		spans[ indexOf(TOS_NODE_ID) ] = size;
		
		for(i = 0; i < size; i++){
			whiteNodes[ i ] = neighborNodes[ i ];
			
			spans[ indexOf(neighborNodes[ i ]) ] = sizeofArray(topology9[ indexOf(neighborNodes[ i ]) ]);
			
		}
		
		myColor = WHITE;
		
	
		printArray("sorted neighborNodes/whiteNodes", whiteNodes);
		printFullArray("spans",  spans);
		
		dbg("booted", "[ %s ] -- Booted.\n", sim_time_string());
		
		currentState = STATE_IDLE;
		call AMControl.start();
	}
	

	/**************** AMControl event handlers *********************/
	event void AMControl.startDone(error_t err) {
		if (err == SUCCESS) {
			call Timer0.startOneShot( (TIMER_MILLI_CHECK_COLOR_THRESHOLD + generateRandom(RANDOM_MAX_VALUE)) );
		}
		else {
			call AMControl.start();
		}
	}

	event void AMControl.stopDone(error_t err) {
		dbg("stopDone", "[ %s ] -- AMControl.stopDone(). \n", sim_time_string());
	}
	

	/**************** Timer0.fired() event handler *********************/
	event void Timer0.fired() {
	
		dbg("Timer0fired", "[ %s ] -- onTimer0Fired: \n", sim_time_string());
		
		if(myColor == WHITE){
			dbg("Timer0fired", "[ %s ] -- WHITE. \n", sim_time_string());
			
			checkIfBlack();
					
		}
	}
	

	/**************** AMSend.sendDone() event handler *********************/
	event void AMSend.sendDone(message_t* msg, error_t err) {

		MDS_message* releasedMsg = (MDS_message*)(call Packet.getPayload(msg, sizeof(MDS_message)));
		
		switch(releasedMsg->_type){
			case GRAY: 
				dbg("sendDone", "[ %s ] -- AMSend.sendDone(): GRAY message from Mote-(%d) --> Mote-(ALL) was sent. \n", sim_time_string(), TOS_NODE_ID);
				
				break;
				
			case BLACK:
				dbg("sendDone", "[ %s ] -- AMSend.sendDone(): BLACK message from from Mote-(%d) --> Mote-(ALL) was sent. \n", sim_time_string(), TOS_NODE_ID);
				
				break;
			
			case WHITE:
				dbg("sendDone", "[ %s ] -- AMSend.sendDone(): WHITE message from from Mote-(%d) --> Mote-(ALL) was sent. \n", sim_time_string(), TOS_NODE_ID);
				
				break;
			default:
				dbgerror("Error", "[ %s ] -- AMSend.sendDone(): No match for the packet from Mote-(%d) --> Mote-(%d) \n", sim_time_string(), TOS_NODE_ID);
		}
		
	}
	
	
	/**************** Receive.receive() event handlers *********************/
	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
	
		am_addr_t sourceNodeid = call AMPacket.source(msg);
		
		if (len == sizeof(MDS_message)) {
			
			MDS_message* rcvpkt = (MDS_message*)payload;
			//dbg("receiveColor","[ %s ] *** Mote-(%d) - %s received from Mote-(%d). \n", sim_time_string(), TOS_NODE_ID, messageTypeToString(rcvpkt->_type), sourceNodeid);
			switch(rcvpkt->_type){
				case BLACK:
					
					dbg("receiveColor","[ %s ] *** Mote-(%d) - BLACK received from Mote-(%d). \n", sim_time_string(), TOS_NODE_ID, sourceNodeid);
					if(!isNodeBlack(sourceNodeid)){
						deleteElement(whiteNodes, sourceNodeid);
						addElement(blackNodes, sourceNodeid);
						
						setZeroSpan(sourceNodeid);
						setZeroSpan(TOS_NODE_ID);
						
						currentState = STATE_GRAY;
					}
					
					if(myColor == WHITE){
						myColor = GRAY;
						sendBroadcastMessage(GRAY);
						
						dbg("printColor","\n\n ************* Mote-(%d) - GRAY ********* \n\n", TOS_NODE_ID);
					}
					
					break;
			
				case GRAY:
				
					dbg("receiveColor","[ %s ] *** Mote-(%d) - GRAY received from Mote-(%d). \n", sim_time_string(),TOS_NODE_ID, sourceNodeid);
					if(!isNodeGray(sourceNodeid)){
						deleteElement(whiteNodes, sourceNodeid);
						addElement(grayNodes, sourceNodeid);
						
						setZeroSpan(sourceNodeid);

						currentState = STATE_IDLE;
						
					}
					
					if(myColor == WHITE){
						checkIfBlack();
					}
					
					break;
				
				case WHITE:
					
					dbg("receiveColor","[ %s ] *** Mote-(%d) - WHITE received from Mote-(%d). \n", sim_time_string(),TOS_NODE_ID, sourceNodeid);
					
					currentState = STATE_IDLE;
					
					break;
					
				default:
					dbgerror("Error", "[ %s ] -- Receive.receive(): No match for the packet from Mote-(%d) --> Mote-(%d) \n", sim_time_string(), sourceNodeid, TOS_NODE_ID);
					currentState = STATE_IDLE;
			}
				
			post printStep();

		}else{
			dbgerror("Error","[ %s ] *** Mote-(%d) - Foreign packet received from Mote-(%d). \n", sim_time_string(), TOS_NODE_ID, sourceNodeid);
		}
		return msg;
	}
}




/*

while(whiteNodes is not empty and TOS_NODE_ID is WHITE){
	if(TOS_NODE_ID is greatest in the whiteNodes)
	then send BLACK message to whiteNodes and grayNodes, color yourself black


	if(rcvpkt is BLACK)
	then add it to blackNodes, color yourself gray and send GRAY message to whiteNodes and grayNodes

	if(rcvpkt is GRAY)
	then add it to grayNodes
	
}

*/

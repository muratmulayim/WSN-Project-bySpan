
#ifndef WSN_PROJECT_H
#define WSN_PROJECT_H

	#ifndef AM_BLINKTORADIO
	#define AM_BLINKTORADIO 6
	#endif
	
	#ifndef TIMER_MILLI_CHECK_COLOR_THRESHOLD
	#define TIMER_MILLI_CHECK_COLOR_THRESHOLD 50
	#endif
	
	#ifndef MAX_ARRAY_SIZE
	#define MAX_ARRAY_SIZE 25
	#endif
	
	#ifndef RANDOM_MAX_VALUE
	#define RANDOM_MAX_VALUE 50
	#endif
	
	#ifndef MY_NULL
	#define MY_NULL 0
	#endif
	
	#ifndef EMPTY_INDEX
	#define EMPTY_INDEX -1
	#endif
	
	#ifndef MAX_QUEUE_SIZE
	#define MAX_QUEUE_SIZE 20
	#endif
	
	
	/*********************************************************/
	enum messageTypes {
		HELLO = 0, 	// Broadcast
		WHITE = 1, 	// Broadcast
		GRAY = 2, 	// Broadcast
		BLACK = 3 	// Broadcast
	};
	
	enum STATES {
		STATE_IDLE = 0,
		STATE_CHECK = 1,
		STATE_BLACK = 2,
		STATE_GRAY = 3,
		STATE_TERM = 4
	};
	
	
	typedef nx_struct MDS_message {
		nx_uint8_t _type;
	} MDS_message;
	
	
	typedef struct {
		MDS_message msg;
		am_addr_t _toNodeid;
	} QueueEntry;
	
	
	am_addr_t topology9[20][20] = {
		{4, 2}, 			// Node 1
		{5, 1}, 			// Node 2
		{7, 8, 9}, 			// Node 3
		{1, 7}, 			// Node 4
		{2, 7, 6}, 			// Node 5
		{5}, 				// Node 6 
		{4, 5, 8, 3, 9}, 	// Node 7 
		{7, 3}, 			// Node 8 
		{3, 7},				// Node 9 
	};
	
	am_addr_t topology20[20][20] = {
		{8, 2, 19, 10}, 				// Node 1
		{17, 1, 3}, 					// Node 2
		{2, 7, 19}, 					// Node 3
		{16, 15}, 						// Node 4
		{10, 20, 16, 18}, 				// Node 5
		{12, 15, 19}, 					// Node 6 
		{3, 19, 12}, 					// Node 7 
		{1, 20, 10}, 					// Node 8 
		{15, 13, 14}, 					// Node 9 
		{1, 8, 5, 16}, 					// Node 10 
		{16, 14}, 						// Node 11
		{6, 7, 16}, 					// Node 12
		{9, 16}, 						// Node 13 
		{11, 9, 16}, 					// Node 14
		{6, 4, 9}, 						// Node 15
		{12, 19, 10, 5, 11, 14, 13, 4}, // Node 16
		{2, 20}, 						// Node 17
		{20, 5}, 						// Node 18
		{7, 3, 1, 16, 6}, 				// Node 19
		{17, 8, 5, 18}	 				// Node 20
	};
	/********************************************************/

#endif

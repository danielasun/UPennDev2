/***************************************************************************
 * Humanistic Robotics VSC Interface Library                               *
 * Version 1.1                                                             *
 * Copyright 2013, Humanistic Robotics, Inc                                *
 ***************************************************************************/
/*
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

/***************************************************************************
 * VSC_TUTORIAL_1 - Basic Example
 *
 *   This tutorial shows how interface with the basic use case of the SRC.
 *   The main loop below will send heartbeats to the VSC at a rate of 20Hz while
 *   reading message data from the VSC continuously.
 *
 ***************************************************************************/

#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <signal.h>
#include <time.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <sys/types.h>
#include <sys/time.h>
#include <sys/select.h>

#include "VehicleMessages.h"
#include "VehicleInterface.h"

/* File descriptor for VSC Interface */
//VscInterfaceType* vscInterface;

#include "estop.h"




int lX=0,lY=0,lZ=0,   rX=0,rY=0,rZ=0;
int lJ=0, rJ=0;
int lU=0,lD=0,lL=0,lR=0,  rU=0, rD=0, rL=0, rR=0;

int estop = 0;


/* File descriptor for VSC Interface */
VscInterfaceType* vscInterface;
struct timespec lastSent, timeNow, lastReceived, timeDiff;
struct timeval timeout;
int max_fd, vsc_fd, retval;
fd_set input;


void signal_handler(int s) {
	printf("Caught signal %d - Shutting down.\n", s);
	vsc_cleanup(vscInterface);

	exit(0);
}

unsigned long diffTime(struct timespec start, struct timespec end, struct timespec *temp) {
	if ((end.tv_nsec - start.tv_nsec) < 0) {
		temp->tv_sec = end.tv_sec - start.tv_sec - 1;
		temp->tv_nsec = 1000000000 + end.tv_nsec - start.tv_nsec;
	} else {
		temp->tv_sec = end.tv_sec - start.tv_sec;
		temp->tv_nsec = end.tv_nsec - start.tv_nsec;
	}
	return temp->tv_nsec;
}

void handleJoystickMsg(VscMsgType *recvMsg) {

//	printf("JOYSTICK MSG!\n");
	JoystickMsgType *joyMsg = (JoystickMsgType*) recvMsg->msg.data;

	lX = vsc_get_stick_value(joyMsg->leftX);
	lY = vsc_get_stick_value(joyMsg->leftY);
	lZ = vsc_get_stick_value( joyMsg->leftZ);

	rX = vsc_get_stick_value(joyMsg->rightX);
	rY = vsc_get_stick_value(joyMsg->rightY);
	rZ = vsc_get_stick_value(joyMsg->rightZ);

	lD=vsc_get_button_value(joyMsg->leftSwitch.home);//down
	lR=vsc_get_button_value(joyMsg->leftSwitch.first);//right
	lU=vsc_get_button_value(joyMsg->leftSwitch.second);//up
	lL=vsc_get_button_value(joyMsg->leftSwitch.third);//left

	rD=vsc_get_button_value(joyMsg->rightSwitch.home);//down
	rR=vsc_get_button_value(joyMsg->rightSwitch.first);//right
	rU=vsc_get_button_value(joyMsg->rightSwitch.second);//up
	rL=vsc_get_button_value(joyMsg->rightSwitch.third);//left

}

int handleHeartbeatMsg(VscMsgType *recvMsg) {
	HeartbeatMsgType *msgPtr = (HeartbeatMsgType*) recvMsg->msg.data;
  estop = msgPtr->EStopStatus;
  return 0;
}

void handleGpsMsg(VscMsgType *recvMsg) {
	GpsMsgType *msgPtr = (GpsMsgType*) recvMsg->msg.data;
	char message[100];

	strncpy(message, (char*)msgPtr->data, recvMsg->msg.length-1);
	message[recvMsg->msg.length-1] = '\0';
	printf("Received GPS Message (0x%x): %s\n", msgPtr->source, message);

	/* TODO: Add application specific code here to handle GPS messages */
}

void handleFeedbackMsg(VscMsgType *recvMsg) {
	UserFeedbackMsgType *msgPtr = (UserFeedbackMsgType*) recvMsg->msg.data;

	printf("Received Feedback Message.  Key: %i, Value %i\n", msgPtr->key, msgPtr->value);

	/* TODO: Add application specific code here to handle feedback messages */
}

int readFromVsc(int *lstick, int*rstick, int *lbutton, int *rbutton) {
	VscMsgType recvMsg;
	int ret=0;
	/* Read all messages */
	while (vsc_read_next_msg(vscInterface, &recvMsg) > 0) {
		/* Read next Vsc Message */
//		printf("[%d] ",recvMsg.msg.msgType);
		switch (recvMsg.msg.msgType) {
		case MSG_VSC_HEARTBEAT:
			ret= handleHeartbeatMsg(&recvMsg);			
			break;
		case MSG_VSC_NMEA_STRING:
			break;
		case MSG_USER_FEEDBACK:
			handleFeedbackMsg(&recvMsg);

			break;
		case MSG_VSC_JOYSTICK:
			handleJoystickMsg(&recvMsg);

			break;
		default:
			printf("ERROR: Receive Error.  Invalid MsgType (0x%02X)\n",
					recvMsg.msg.msgType);
			break;
		}
	}

//X forward, Y left
	lstick[0]=lY;
	lstick[1]=-lX;
	lstick[2]=lZ;

	rstick[0]=rY;
	rstick[1]=-rX;
	rstick[2]=rZ;

	lbutton[0]=lU;
	lbutton[1]=lD;
	lbutton[2]=lL;
	lbutton[3]=lR;

	rbutton[0]=rU;
	rbutton[1]=rD;
	rbutton[2]=rL;
	rbutton[3]=rR;


	return ret;
}




void estop_init(char* ch, int baud){

	// Catch CTRL-C 
	signal(SIGINT, signal_handler);

	// Open VSC Interface 
	vscInterface = vsc_initialize(ch,baud);

	if (vscInterface == NULL) {
		printf("Opening VSC Interface failed.\n");
		exit(EXIT_FAILURE);
	}

	printf("VSC Interface opened.\n");

	// Initialize the input set 
	vsc_fd = vsc_get_fd(vscInterface);
	FD_ZERO(&input);
	FD_SET(vsc_fd, &input);
	max_fd = vsc_fd + 1;

	// Reset timing values to the current time 
	clock_gettime(CLOCK_REALTIME, &lastSent);
	clock_gettime(CLOCK_REALTIME, &lastReceived);

	// Send Heartbeat Message to VSC 
	vsc_send_heartbeat(vscInterface, ESTOP_STATUS_NOT_SET);

	lX=0;	lY=0;	lZ=0;
	rX=0;	rY=0;	rZ=0;
	lU=0;lD=0;lL=0;lR=0;
	rU=0;rD=0;rL=0;rR=0;
	estop=0;
}


void estop_shutdown(){
/* Clean up */
	printf("Shutting down.\n");
	vsc_cleanup(vscInterface);
}



int estop_update(int *lstick, int*rstick, int *lbutton, int *rbutton){

	/* Get current clock time */
		clock_gettime(CLOCK_REALTIME, &timeNow);

		/* Send Heartbeat messages every 50 Milliseconds (20 Hz) */
		if (diffTime(lastSent, timeNow, &timeDiff) > 50000) {
			/* Get current clock time */
			lastSent = timeNow;

			/* Send Heartbeat */
			vsc_send_heartbeat(vscInterface, ESTOP_STATUS_NOT_SET);
		}






	/* Send Display Mode to VSC */

	vsc_send_user_feedback(vscInterface, VSC_USER_DISPLAY_MODE, DISPLAY_MODE_CUSTOM_TEXT);
	vsc_send_user_feedback_string(vscInterface, VSC_USER_DISPLAY_ROW_1, "          WHY       ");
	vsc_send_user_feedback_string(vscInterface, VSC_USER_DISPLAY_ROW_2, "         AM I       ");
	vsc_send_user_feedback_string(vscInterface, VSC_USER_DISPLAY_ROW_3, "          SO        ");
//vsc_send_user_feedback_string(vscInterface, VSC_USER_DISPLAY_ROW_4, "       AWESOME?     ");










		/* Initialize the timeout structure for 50 milliseconds*/
		timeout.tv_sec = 0;
		timeout.tv_usec = (50000 - (diffTime(lastSent, timeNow, &timeDiff) * .001));

		/* Perform select on serial port or Timeout */
		FD_ZERO(&input);
		FD_SET(vsc_fd, &input);
		max_fd = vsc_fd + 1;
		retval = select(max_fd, &input, NULL, NULL, &timeout);

		/* See if there was an error */
		if (retval < 0) {
			fprintf(stderr, "vsc_example: select failed");
		} else if (retval == 0) {
			/* No data received - Check to see when we last recieved data from the VSC */
			clock_gettime(CLOCK_REALTIME, &timeNow);
			diffTime(lastReceived, timeNow, &timeDiff);

			if(timeDiff.tv_sec > 0) {
				printf("vsc_example: WARNING: No data received from VSC in %li.%09li seconds!\n",
						timeDiff.tv_sec, timeDiff.tv_nsec);
			}
		} else {
			/* Input received, check to see if its from the VSC */
			if (FD_ISSET(vsc_fd, &input)) {
				/* Read from VSC */
				int ret = readFromVsc(lstick,rstick,lbutton,rbutton);
		
				/* Record the last time input was recieved from the VSC */
				clock_gettime(CLOCK_REALTIME, &lastReceived);
				return estop;
			} else {
				fprintf(stderr, "vsc_example: invalid fd set");
			}
		}
		return estop;
}
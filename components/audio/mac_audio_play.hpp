#ifndef OPPVS_MAC_AUDIO_PLAY_HPP
#define OPPVS_MAC_AUDIO_PLAY_HPP

#import <AudioToolbox/AudioToolbox.h>
#import <CoreAudio/CoreAudio.h>
//#import <CoreFoundation/CoreFoundation.h>
#include "mac_utility/CAStreamBasicDescription.h"
#include "mac_utility/CARingBuffer.h"
#include "audio_play.hpp"
#include "mac_audio_resampler.hpp"

namespace oppvs {
	#define checkErr( err) \
	if(err) {\
		OSStatus error = static_cast<OSStatus>(err);\
		printf("MacAudioPlay Error: %ld ->  %s:  %d\n",  (long)error,\
				   __FILE__, \
				   __LINE__\
				   );\
		fflush(stdout);\
		return err; \
	}

	class MacAudioPlay : public AudioPlay
	{
	public:
		MacAudioPlay();
		MacAudioPlay(const AudioDevice&, uint64_t, uint32_t);
		~MacAudioPlay();
		int init();
		int start();
		int stop();
		void cleanup();
		void attachBuffer(CARingBuffer*);

		double getFirstInputTime();
		void setFirstInputTime(double);

	private:
		//AudioUnits and Graph
		AUGraph m_graph;
		AUNode m_varispeedNode;
		AudioUnit m_varispeedUnit;
		AUNode m_outputNode;
		AudioUnit m_outputUnit;
        //AUNode m_converterNode;
        //AudioUnit m_converterUnit;
        
		CARingBuffer *m_buffer;
		double m_firstInputTime;
		double m_firstOutputTime;
		double m_offset;
        
        AudioConverterRef m_converter;  //Used to convert interleave to deinterleave
        AudioBufferList* m_inBuffer;  //Buffer to be used as input of converter
        AudioBufferList* m_outBuffer; //Buffer to be used as output of converter
        
		CAStreamBasicDescription m_inputFormat;

		OSStatus setupGraph(AudioDeviceID deviceid);
		OSStatus makeGraph();
		OSStatus setOutputDevice(AudioDeviceID deviceid);
		OSStatus setupBuffer();
		bool isRunning();

		static OSStatus OutputProc(void *inRefCon,
							 AudioUnitRenderActionFlags *ioActionFlags,
							 const AudioTimeStamp *TimeStamp,
							 UInt32 inBusNumber,
							 UInt32 inNumberFrames,
							 AudioBufferList * ioData);

	};

} // oppvs

#endif // OPPVS_MAC_AUDIO_PLAY_HPP

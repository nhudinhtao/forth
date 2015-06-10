#ifndef OPPVS_MESSAGE_HANDLING_HPP
#define OPPVS_MESSAGE_HANDLING_HPP

#include "datatypes.hpp"
#include "concurrent_queue.hpp"
#include "tsqueue.hpp"
#include "cache_buffer.hpp"

namespace oppvs
{

	const static uint8_t FLAG_START_FRAME = 1;
	const static uint8_t FLAG_MIDDLE_FRAME = 2;
	const static uint8_t FLAG_END_FRAME = 3;
	const static uint16_t MAX_FRAMES_IN_POOL = 10;
	const static uint8_t MESSAGE_HEADER_SIZE = 4;

	class Message
	{
	public:
		Message();
		virtual ~Message();
		void setFlag(uint8_t);
		uint8_t getFlag();
		void setSource(uint8_t);
		uint8_t getSource();
		void setSegID(uint16_t seg);
		uint16_t getSegID();
		void setData(const uint8_t *data, uint16_t length);
		uint16_t getLength();
		void setLength(uint16_t);
		uint8_t* getData();

	private:
		uint16_t m_length;
		uint8_t m_data[OPPVS_NETWORK_PACKET_LENGTH];
	};

	class MessageHandling
	{
	public:
		MessageHandling();
		virtual ~MessageHandling();

		void setNumClients(uint8_t clients);
		void addMessage(PixelBuffer& pf);
		void getNextMessage(uint8_t** pdata, uint16_t* length);
		bool releaseMessage();
		bool isEmptyPool();
	private:
		tsqueue<std::shared_ptr<Message>> m_messagePool;
		uint16_t m_numFramesInPool;
		uint8_t m_numClients;
		uint8_t m_sentClients;
	};

	class MessageParsing
	{
	public:
		MessageParsing();
		virtual ~MessageParsing();

		void updateMessage(Message&);
		void setCacheBuffer(CacheBuffer *cb);
	private:
		CacheBuffer *m_cacheBuffer;
	};

};


#endif
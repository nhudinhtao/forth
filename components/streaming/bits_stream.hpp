/*
	Bitstream = video stream + audio stream
*/

#ifndef OPPVS_BITS_STREAM_HPP
#define OPPVS_BITS_STREAM_HPP

#include "brg_types.h"
#include <stddef.h>

namespace oppvs
{
	class BitsStream
	{
		public:
			BitsStream();
			BitsStream(uint8_t* data, uint32_t length);
			virtual ~BitsStream();

		private:
			uint8_t* m_data;
			uint32_t m_length;
	};
}

#endif
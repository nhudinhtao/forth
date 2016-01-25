#ifndef OPPVS_IOS_VIDEO_CAPTURE_HPP
#define OPPVS_IOS_VIDEO_CAPTURE_HPP

#include "video_capture.hpp"

namespace oppvs {
	class IosVideoCapture : public VideoCapture
	{
	public:
		IosVideoCapture();
		~IosVideoCapture();

		void setup();
	};
} // oppvs

#endif // OPPVS_IOS_VIDEO_CAPTURE_HPP

{
    'includes': [
        '../../common.gypi'
    ],

    'targets': [
        {
            'target_name': 'network_engine',
            'type': 'shared_library',
            'dependencies': [
                '../misc/misc.gyp:libmisc2',
            ],
            'include_dirs': [
                '../../libs/libsrtp/include',
                '../../libs/libsrtp/crypto/include',
                '../include',
                '../misc'
            ],

            'conditions': [
                ['OS == "mac"', {
                    'defines': [
                        '__APPLE_USE_RFC_3542'
                    ],
                    'xcode_settings': {
                        'OTHER_CPLUSPLUSFLAGS' : ['-std=c++11'],
                    },
                    'libraries': [
                    
                        '../../libs/libsrtp.a',
                    ],

                }],
                ['OS == "linux"', {
                    'libraries': [
                    
                        '../../../libs/libsrtp.a',
                        '-lssl',
                        '-lcrypto'
                    ],
                }]
            ],

            'sources': [
                #headers
                'client_socket.hpp',
                'data_stream.hpp',
                'dynamic_buffer.hpp',
                'ipaddress.hpp',
                'physical_socket.hpp',
                'server_socket.hpp',
                'socket_address.hpp',
                'srtp_socket.hpp',
                'stun_auth.hpp',
                'stun_header.hpp',
                'stun_message_handler.hpp',
                'stun_socket_address.hpp',
                'stun_socket.hpp',
                'signaling_common.hpp',
                'signaling_manager.hpp',
                'signaling_message_builder.hpp',
                'signaling_message_reader.hpp',

                #sources
                 'client_socket.cpp',
                'data_stream.cpp',
                'dynamic_buffer.cpp',
                'ipaddress.cpp',
                'physical_socket.cpp',
                'server_socket.cpp',
                'socket_address.cpp',
                'srtp_socket.cpp',
                'stun_message_handler.cpp',
                'stun_socket_address.cpp',
                'stun_socket.cpp',
                'signaling_manager.cpp',
                'signaling_message_builder.cpp',
                'signaling_message_reader.cpp'
            ]

        }
    ],


}
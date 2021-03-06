{
	'variables': {
		'oppvs_root%': '<(DEPTH)/../',
        'conditions': [
            ['OS == "ios"', {
                'oppvs_3rdlibs_path': '<!(echo "$HOME/cerbero/dist/ios_universal")',
                'oppvs_xcode_path': '<!(echo `xcode-select --print-path`)'  
            }],
            ['OS == "mac"', {
                'oppvs_3rdlibs_path': '<!(echo "$HOME/cerbero/dist/darwin_x86_64")'        
            }],
        ],        
        
	},

    'conditions': [
        ['OS == "ios"', {
            'xcode_settings': {
                'SDKROOT': 'iphoneos',
                'ARCHS': [
                    '$(ARCHS_STANDARD)'
                ]
            }
        }]
    ],

	'target_defaults': {
		'conditions': [
            ['OS == "linux"', {
            	'cflags': [
            		'-fPIC'
            	],
    			'cflags_cc': [
            		'-fPIC',
            		'-std=c++11'
    			],
    			'ldflags': [
    				'-pthread',
    			]
            }],
            ['OS == "mac"', {
                'default_configuration': 'Debug',
                'configurations': {
                    'Debug': {
                        'DEBUG_INFORMATION_FORMAT': 'dwarf',
                    },
                    'Release': {
                        'DEBUG_INFORMATION_FORMAT': 'dwarf-with-dsym',
                    }
                }
                
            }],

            ['OS == "android"', {
                'defines': [ 'ANDROID' ],
            }],

            ['OS == "ios"', {
                'default_configuration': 'Debug',
                'configurations': {
                    'Debug': {
                        'DEBUG_INFORMATION_FORMAT': 'dwarf',
                    },
                    'Release': {
                        'DEBUG_INFORMATION_FORMAT': 'dwarf-with-dsym',
                    }
                },
                'xcode_settings': {
                    'CODE_SIGN_IDENTITY[sdk=iphoneos*': 'iPhone Developer',
                    'SUPPORTED_PLATFORMS': 'iphonesimulator iphoneos',
                    'OTHER_CPLUSPLUSFLAGS' : ['-std=c++11'],
                },

                'defines': [ 'FORTH_IOS' ],

            }], # OS=="ios"
        ],
		
	}
}
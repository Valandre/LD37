{
	"s3d": {
		"Scene": {
			"DirLight": {
				"Light": {
					"priority": 10
				}
			}
		},
		"Renderer": {
			"Lights": {
				"LightSystem": {
					"ambientLight": "#CEC4B1"
				}
			},
			"Shaders": {
				"ambient": {
					"shader shaders Composite": {
						"bloomPower": 5,
						"global_saturation": 1.1,
						"fogColor": "#221938",
						"global_contrast": 1.1,
						"dofPower": 0.5,
						"fogStart": 0.1,
						"hasFOG": true,
						"global_brightness": 0.02,
						"bloomAmount": 1,
						"dofStart": 0.001,
						"hasBLOOM": true,
						"fogAmount": 0.95,
						"dofAmount": 4,
						"hasDOF": true,
						"fogPower": 3
					}
				}
			}
		}
	}
}
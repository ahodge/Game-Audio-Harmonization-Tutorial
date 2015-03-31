
#pragma strict

var player : Transform;
var playableMoodBoxes : MoodBox[];

var timePerChar : float = 0.125f;

private var currentMoodBox : int = 0;
private var textAnimation : int = 0;
private var timer : float = 0.0f;
private var camOffset : Vector3 = Vector3.zero;

function Start () {
	if (!player)
		player = GameObject.FindWithTag ("Player").transform;	
			
	var leftIcon = new GameObject ("Left Arrow", GUIText);
	var rightIcon = new GameObject ("Right Arrow", GUIText);

#if UNITY_IPHONE || UNITY_ANDROID || UNITY_WP8 || UNITY_BLACKBERRY
	leftIcon.GetComponent.<GUIText>().text = "<";
#else
	leftIcon.GetComponent.<GUIText>().text = "< backspace";		
#endif
	
	leftIcon.GetComponent.<GUIText>().font = GetComponent.<GUIText>().font;
	leftIcon.GetComponent.<GUIText>().material = GetComponent.<GUIText>().material;
	leftIcon.GetComponent.<GUIText>().anchor = TextAnchor.UpperLeft;
	leftIcon.gameObject.layer = ( LayerMask.NameToLayer ("Adventure"));
	
	leftIcon.transform.position.x = 0.01f;
	leftIcon.transform.position.y = 0.1f;

#if UNITY_IPHONE || UNITY_ANDROID || UNITY_WP8 || UNITY_BLACKBERRY
	rightIcon.GetComponent.<GUIText>().text = ">";
#else
	rightIcon.GetComponent.<GUIText>().text = "space >";		
#endif
	rightIcon.GetComponent.<GUIText>().font = GetComponent.<GUIText>().font;
	rightIcon.GetComponent.<GUIText>().material = GetComponent.<GUIText>().material;
	rightIcon.GetComponent.<GUIText>().anchor = TextAnchor.UpperRight;
	rightIcon.gameObject.layer = ( LayerMask.NameToLayer ("Adventure"));
			
	rightIcon.transform.position.x = 0.99f;
	rightIcon.transform.position.y = 0.1f;		
}

function OnEnable () {	
	textAnimation = 0;
	timer = timePerChar;
	
	camOffset = Camera.main.transform.position - player.position;
	
	BeamToBox (currentMoodBox);
		
	if (player) {
		var ctrler : PlayerMoveController = player.GetComponent.<PlayerMoveController> ();
		ctrler.enabled = false;		
	}
	
	GetComponent.<GUIText>().enabled = true;
}

function OnDisable () {
	// and back to normal player control
	
	if (player) {
		var ctrler : PlayerMoveController = player.GetComponent.<PlayerMoveController> ();
		ctrler.enabled = true;		
	}
	
	GetComponent.<GUIText>().enabled = false;	
}

function Update () {
	GetComponent.<GUIText>().text = "AngryBots \n \n";
	GetComponent.<GUIText>().text += playableMoodBoxes[currentMoodBox].data.adventureString.Substring (0, textAnimation);
	
	Debug.Log (GetComponent.<GUIText>().text);
	
	if (textAnimation >= playableMoodBoxes[currentMoodBox].data.adventureString.Length ) {
			
	}
	else {
		timer -= Time.deltaTime;
		if (timer <= 0.0f) {
			textAnimation++;
			timer = timePerChar;
		}
	}
	
	CheckInput ();
}

function BeamToBox (index : int) {
	if (index > playableMoodBoxes.Length)
		return;
		
	player.position = playableMoodBoxes[index].transform.position;
	Camera.main.transform.position = player.position + camOffset;
	textAnimation = 0;
	timer = timePerChar;
}

function CheckInput () {
	var input : int = 0;
	
	#if UNITY_IPHONE || UNITY_ANDROID || UNITY_WP8 || UNITY_BLACKBERRY
   		for (var touch : Touch in Input.touches) {
        	if (touch.phase == TouchPhase.Ended && touch.phase != TouchPhase.Canceled) {
            	if (touch.position.x < Screen.width / 2)
            		input = -1;
            	else 
            		input = 1;
        	}
    	}
	#else
		if (Input.GetKeyUp (KeyCode.Space))
			input = 1;
		else if (Input.GetKeyUp (KeyCode.Backspace))
			input = -1;
	#endif
	
	if (input != 0) {
		if (textAnimation < playableMoodBoxes[currentMoodBox].data.adventureString.Length) {
			textAnimation = playableMoodBoxes[currentMoodBox].data.adventureString.Length;
			input = 0;
		}
	}
			
	if (input != 0) {
		if ((currentMoodBox - playableMoodBoxes.Length) == -1 && input < 0) 
			input = 0;
		if (currentMoodBox == 0 && input < 0)
			input = 0;
			
		if (input) {
			currentMoodBox = (input + currentMoodBox) % playableMoodBoxes.Length;
			BeamToBox (currentMoodBox);
		}
	}
}

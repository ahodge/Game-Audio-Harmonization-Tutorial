
#pragma strict

static var brokenMaterial : Material = null;

function Start () {
	if (brokenMaterial == null)
		brokenMaterial = new Material (GetComponent.<Renderer>().sharedMaterial);
		
	GetComponent.<Renderer>().material = brokenMaterial;
}

function OnWillRenderObject () {
	brokenMaterial.mainTextureOffset.x += Random.Range (1.0, 2.0);
}
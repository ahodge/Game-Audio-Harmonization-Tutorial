#pragma strict
#pragma downcast
import System.Collections.Generic;

public var affected : List.<GameObject> = new List.<GameObject> ();

ActivateAffected (false);

function OnTriggerEnter (other : Collider) {
	if (other.tag == "Player")
		ActivateAffected (true);
}

function OnTriggerExit (other : Collider) {
	if (other.tag == "Player")
		ActivateAffected (false);
}

function ActivateAffected (state : boolean) {
	for (var go : GameObject in affected) {
		if (go == null)
			continue;
		go.SetActive (state);
		yield;
	}
	for (var tr : Transform in transform) {
		tr.gameObject.SetActive (state);
		yield;
	}
}

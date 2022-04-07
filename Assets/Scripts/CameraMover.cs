using UnityEngine;

public class CameraMover : MonoBehaviour
{
    [SerializeField] private float speed;
    [SerializeField] private bool manualStart;
    private bool isMoving;

    private void Update()
    {
        if (Input.GetButtonDown("Jump") && !manualStart)
        {
            isMoving = !isMoving;
        }

        if (isMoving || !manualStart)
        {
            transform.position += transform.forward * (speed * Time.deltaTime);
        }
    }
}

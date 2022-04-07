using UnityEngine;

public class MicInput : MonoBehaviour
{
    [SerializeField] private float rmsMultiplier = 20;
    private float[] micSamples;
    private int sampleSize = 128;
    private AudioClip record;

    private float temp;
    public float rmsValueMic;
    
    private void Awake()
    {
        var device = Microphone.devices[0];

        var audioSource = GetComponent<AudioSource>();
        audioSource.clip = Microphone.Start(device, true, 10, 44100);
        audioSource.Play();
    }

    private void Start()
    {
        record = GetComponent<AudioSource>().clip;
    }

    private void FixedUpdate()
    {
        AnalyzeMic();
    }

    private void AnalyzeMic()
    {
        micSamples = new float[sampleSize];
        var micPosition = Microphone.GetPosition(null) - (sampleSize + 1);
        if (micPosition < 0)
        {
            return;
        }
        record.GetData(micSamples, micPosition);

        temp = Mathf.Sqrt(CalculateRMS(micSamples) / sampleSize) * rmsMultiplier;
        rmsValueMic = Mathf.Lerp(rmsValueMic, temp, Time.deltaTime);
        rmsValueMic = Mathf.Clamp01(rmsValueMic);
    }

    private float CalculateRMS(float[] samples)
    {
        float sum = 0;
        for (var i = 0; i < sampleSize; ++i)
        {
            sum += samples[i] * samples[i];
        }

        return sum;
    }
}
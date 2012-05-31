#ifndef __ALSA_UTIL_H__
#define __ALSA_UTIL_H__

// use the newer alsa api
#define ALSA_PCM_NEW_HW_PARAMS_API
#include <alsa/asoundlib.h>

/**
 * print the alsa library version
 */
void print_alsa_lib_version();

/**
 * print out available alsa formats
 */
void print_alsa_formats();

/**
 * sets the audio parameters from the given defines
 *
 * handle - alsa device handle
 * params - alsa parameter object
 *
 * return - 0 on success 
 */
int set_device_params(snd_pcm_t *handle, snd_pcm_hw_params_t *params);

/**
 * prints out useful audio parameters for the given device
 *
 * handle - alsa device handle
 * params - alsa parameter object
 * full - flag indicating if all parameters should be printed,
 *          otherwise only a few important ones are
 */
void print_device_params(snd_pcm_t *handle, snd_pcm_hw_params_t *params, int full);



#endif

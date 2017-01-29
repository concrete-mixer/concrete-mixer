public class FxChain {
    Chooser chooser;
    Panner panner;
    Fader fader;

    Gain inputGain;
    Pan2 outputPan;
    0 => outputPan.gain;

    // spork ~ panner.initialise(outputPan);
    Fx @ fxChain[];

    UGen outLeft, outRight;

    outLeft => Mixer.leftOut;
    outRight => Mixer.rightOut;
    Mixer.fxIn => inputGain;

    // Fx chain is mono, let's make a little cheap stereo
    // via a short delay on one of the channels
    Delay delay;
    chooser.getDur( 0.01, 0.04 ) => delay.delay;

    // should left side be delayed or right?
    if ( chooser.getInt( 0, 1 ) ) {
        outputPan.left => outLeft;
        outputPan.right => delay => outRight;
    }
    else {
        outputPan.left => delay => outLeft;
        outputPan.right => outRight;
    }

    fun void fxChainBuild(int choice) {
        // Define the fx chains. Originally we defined them randomly
        // but this meant much of the time the resulting chains were
        // suboptimal, if not nonsensical, so here we (lengthily) define
        // some reasonable sounding chains
        if ( choice == 1 ) {
            [
                new FxFilter,
                new FxDelay
            ] @=> fxChain;
        }

        if ( choice == 2 ) {
            [
                new FxDelayVariable,
                new FxDelay
            ] @=> fxChain;
        }

        if ( choice == 3 ) {
            [
                new FxDelay,
                new FxHarmonicDelay
            ] @=> fxChain;
        }

        if ( choice == 4 ) {
            [
                new FxHarmonicDelay,
                new FxDelay
            ] @=> fxChain;
        }

        if ( choice == 5 ) {
            [
                new FxFlanger,
                new FxDelay
            ] @=> fxChain;
        }

        if ( choice == 6 ) {
            [
                new FxFlanger,
                new FxDelayVariable
            ] @=> fxChain;
        }

        if ( choice == 7 ) {
            [
                new FxFilter,
                new FxDelayVariable
            ] @=> fxChain;
        }

        if ( choice == 8 ) {
            [
                new FxGate,
                new FxDelayVariable
            ] @=> fxChain;
        }

        if ( choice == 9 ) {
            [
                new FxDelay,
                new FxReverb,
                new FxChorus
            ] @=> fxChain;
        }

        if ( choice == 10 ) {
            [
                new FxDelay,
                new FxFilter,
                new FxReverb
            ] @=> fxChain;
        }

        if ( choice == 11 ) {
            [
                new FxDelay,
                new FxFlanger,
                new FxReverb
            ] @=> fxChain;
        }

        if ( choice == 12 ) {
            [
                new FxDelayVariable,
                new FxDelay
            ] @=> fxChain;
        }

        if ( choice == 13 ) {
            [
                new FxFilter,
                new FxGate,
                new FxDelay
            ] @=> fxChain;
        }

        if ( choice == 14 ) {
            [
                new FxRingMod,
                new FxFlanger,
                new FxDelay
            ] @=> fxChain;
        }

        if ( choice == 15 ) {
            [
                new FxRingMod,
                new FxFilter,
                new FxDelayVariable
            ] @=> fxChain;
        }

        if ( choice == 16 ) {
            [
                new FxRingMod,
                new FxHarmonicDelay,
                new FxDelay
            ] @=> fxChain;
        }

        if ( choice == 17 ) {
            [
                new FxDelay,
                new FxDownSampler
            ] @=> fxChain;
        }

        if ( choice == 18 ) {
            [
                new FxDownSampler,
                new FxDelayVariable
            ] @=> fxChain;
        }

        if ( choice == 19 ) {
            [
                new FxDownSampler,
                new FxDelay,
                new FxFlanger
            ] @=> fxChain;
        }

        // Beyond here all choices are for Config.rpi == 0 only
        // because they feature Chugens
        if ( choice == 20 ) {
            [
                new FxGate,
                new FxReverseDelay
            ] @=> fxChain;
        }

        if ( choice == 21 ) {
            [
                new FxFlanger,
                new FxReverseDelay
            ] @=> fxChain;
        }

        if ( choice == 22 ) {
            [
                new FxDelayVariable,
                new FxReverseDelay
            ] @=> fxChain;
        }

        if ( choice == 23 ) {
            [
                new FxFilter,
                new FxDelayVariable,
                new FxReverseDelay
            ] @=> fxChain;
        }

        if ( choice == 24 ) {
            [
                new FxFilter,
                new FxReverseDelay
            ] @=> fxChain;
        }

        if ( choice == 25 ) {
            [
                new FxGate,
                new FxReverseDelay
            ] @=> fxChain;
        }

        if ( choice == 26 ) {
            // FxPassthrough required for a chain
            // as ChucK doesn't allow array ref assignment
            // of single item Object array...
            //
            // Although FxReverb is an instantiation of an object
            // of class Fx, [ new FxReverb ] @=> fxChain throws
            // cannot assign '@=>' on types 'FxReverb[]' @=> 'Fx[]'...
            [
                new FxReverb,
                new FxPassthrough
            ] @=> fxChain;
        }

        <<< "STARTING FX CHAIN: ", choice >>>;
        fxChainFx();
    }

    fun void fxChainFx() {
        for ( int i; i < fxChain.cap(); i++ ) {
            fxChain[ i ] @=> Fx fx;
            <<< i + 1, fx.idString() >>>;
            fx.initialise();

            if ( i == 0 ) {
                inputGain => fx.input;
            }
            else {
                fxChain[ i - 1 ] @=> Fx upstreamFx;
                upstreamFx.output => fx.input;
            }

            if ( i == fxChain.cap() - 1 ) {
                fx.output => outputPan;
            }
        }

        <<< "END OF FXCHAIN INFO" >>>;
    }

    fun void tearDown() {
        for ( 0 => int i; i < fxChain.cap(); i++ ) {
            fxChain[ i ].tearDown();
        }

        // need to give time for fx teardowns to process
        Time.barDur => now;

        // now we go through and clean up
        for ( 0 => int i; i < fxChain.cap(); i++ ) {
            fxChain[ i ] @=> Fx fx;

            if ( i == 0 ) {
                inputGain =< fx.input;
            }
            else {
                fxChain[ i - 1 ] @=> Fx upstreamFx;
                upstreamFx.output =< fx.input;
            }

            if ( i == fxChain.cap() - 1 ) {
                fx.output =< outputPan;
            }
        }

        outputPan.left =< outLeft;
        outputPan.right =< outRight;

        outLeft =< Mixer.leftOut;
        outRight =< Mixer.rightOut;
    }

    fun void fadeIn(dur fadeTime) {
        fader.fadeIn( fadeTime, 0.8, outputPan );
    }

    fun void fadeOut(dur fadeTime) {
        fader.fadeOutBlocking( fadeTime, outputPan );
    }
}

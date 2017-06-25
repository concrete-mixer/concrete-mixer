public class FxChain {
    Chooser chooser;
    Panner panner;
    Fader fader;

    Gain inputGain;
    Pan2 outputPan;
    0 => outputPan.gain;

    // spork ~ panner.initialise(outputPan);
    Fx @ fxChain[];

    Mixer.fxIn => inputGain;

    outputPan.left => Mixer.leftOut;
    outputPan.right => Mixer.rightOut;

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
                new FxFlanger,
                new FxDelay
            ] @=> fxChain;
        }

        if ( choice == 5 ) {
            [
                new FxFlanger,
                new FxDelayVariable
            ] @=> fxChain;
        }

        if ( choice == 6 ) {
            [
                new FxFilter,
                new FxDelayVariable
            ] @=> fxChain;
        }

        if ( choice == 7 ) {
            [
                new FxGate,
                new FxDelayVariable
            ] @=> fxChain;
        }

        if ( choice == 8 ) {
            [
                new FxDelay,
                new FxReverb
            ] @=> fxChain;
        }

        if ( choice == 9 ) {
            [
                new FxDelayVariable,
                new FxDelay
            ] @=> fxChain;
        }

        if ( choice == 10 ) {
            [
                new FxFilter,
                new FxGate,
                new FxDelay
            ] @=> fxChain;
        }

        if ( choice == 11 ) {
            [
                new FxRingMod,
                new FxDelay
            ] @=> fxChain;
        }

        if ( choice == 12 ) {
            [
                new FxRingMod,
                new FxHarmonicDelay,
                new FxDelay
            ] @=> fxChain;
        }

        // Beyond here all choices are for Config.rpi == 0 only
        // because they feature Chugens
        if ( choice == 13 ) {
            [
                new FxGate,
                new FxReverseDelay
            ] @=> fxChain;
        }

        if ( choice == 14 ) {
            [
                new FxFlanger,
                new FxReverseDelay
            ] @=> fxChain;
        }

        if ( choice == 15 ) {
            [
                new FxDelayVariable,
                new FxReverseDelay
            ] @=> fxChain;
        }

        if ( choice == 16 ) {
            [
                new FxFilter,
                new FxDelayVariable,
                new FxReverseDelay
            ] @=> fxChain;
        }

        if ( choice == 17 ) {
            [
                new FxFilter,
                new FxReverseDelay
            ] @=> fxChain;
        }

        if ( choice == 18 ) {
            [
                new FxGate,
                new FxReverseDelay
            ] @=> fxChain;
        }

        if ( choice == 19 ) {
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

        if ( choice == 20 ) {
            [
                new FxSpeedDelay,
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

        outputPan.left =< Mixer.leftOut;
        outputPan.right =< Mixer.rightOut;
    }

    fun void fadeIn(dur fadeTime) {
        fader.fadeIn( fadeTime, 1.0, outputPan );
    }

    fun void fadeOut(dur fadeTime) {
        fader.fadeOutBlocking( fadeTime, outputPan );
    }
}

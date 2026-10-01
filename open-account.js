/**
 * Deccan Finance Limited Onboarding - Onboarding Wizard JavaScript
 * Manages step navigation, signature pad, and live webcam capture.
 */

document.addEventListener('DOMContentLoaded', () => {
    // Current state
    let currentStep = 1;
    const accountType = document.getElementById('account_type_field').value;

    // DOM Elements
    const form = document.getElementById('onboarding-main-form');
    const btnBack = document.getElementById('btn-nav-back');
    const btnNext = document.getElementById('btn-nav-next');
    const btnSubmit = document.getElementById('btn-nav-submit');
    const footerActions = document.getElementById('onboard-footer-actions');
    const errorAlert = document.getElementById('submit-error-alert');

    // Camera variables
    let portraitStream = null;
    let panStream = null;
    let aadhaarStream = null;

    // Signature Pad Variables
    const canvas = document.getElementById('signature-canvas');
    const ctx = canvas.getContext('2d');
    let isDrawing = false;
    let isSignatureDrawn = false;

    // Set Canvas Dimensions relative to its actual visual size
    function resizeCanvas() {
        const rect = canvas.getBoundingClientRect();
        canvas.width = rect.width;
        canvas.height = rect.height;
        // Restore draw settings
        ctx.strokeStyle = '#031f73';
        ctx.lineWidth = 3;
        ctx.lineCap = 'round';
        ctx.lineJoin = 'round';
        isSignatureDrawn = false; // Need to redraw if resized
    }
    
    // Initial resize and listening
    resizeCanvas();
    window.addEventListener('resize', resizeCanvas);

    // Signature Drawing Logic
    function getMousePos(e) {
        const rect = canvas.getBoundingClientRect();
        const clientX = e.touches ? e.touches[0].clientX : e.clientX;
        const clientY = e.touches ? e.touches[0].clientY : e.clientY;
        return {
            x: clientX - rect.left,
            y: clientY - rect.top
        };
    }

    function startDrawing(e) {
        isDrawing = true;
        const pos = getMousePos(e);
        ctx.beginPath();
        ctx.moveTo(pos.x, pos.y);
        isSignatureDrawn = true;
        e.preventDefault();
    }

    function draw(e) {
        if (!isDrawing) return;
        const pos = getMousePos(e);
        ctx.lineTo(pos.x, pos.y);
        ctx.stroke();
        e.preventDefault();
    }

    function stopDrawing() {
        isDrawing = false;
    }

    // Canvas Listeners
    canvas.addEventListener('mousedown', startDrawing);
    canvas.addEventListener('mousemove', draw);
    canvas.addEventListener('mouseup', stopDrawing);
    canvas.addEventListener('mouseleave', stopDrawing);

    canvas.addEventListener('touchstart', startDrawing);
    canvas.addEventListener('touchmove', draw);
    canvas.addEventListener('touchend', stopDrawing);

    // Clear Signature
    document.getElementById('btn-clear-sig').addEventListener('click', () => {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        isSignatureDrawn = false;
        document.getElementById('signature_data').value = '';
    });

    /* --- HTML5 Camera Controllers --- */

    async function startCamera(videoElement) {
        try {
            const stream = await navigator.mediaDevices.getUserMedia({
                video: {
                    facingMode: videoElement.id === 'portrait-video' ? 'user' : 'environment',
                    width: { ideal: 640 },
                    height: { ideal: 480 }
                },
                audio: false
            });
            videoElement.srcObject = stream;
            return stream;
        } catch (err) {
            console.error('Camera access denied or unavailable: ', err);
            alert('Camera Access Required: Please enable camera permissions to complete KYC onboarding.');
            return null;
        }
    }

    function stopStream(stream) {
        if (stream) {
            stream.getTracks().forEach(track => track.stop());
        }
    }

    function captureSnapshot(videoElement, previewImgElement, hiddenInputId) {
        const captureCanvas = document.createElement('canvas');
        captureCanvas.width = videoElement.videoWidth || 640;
        captureCanvas.height = videoElement.videoHeight || 480;
        
        const captureCtx = captureCanvas.getContext('2d');
        captureCtx.drawImage(videoElement, 0, 0, captureCanvas.width, captureCanvas.height);
        
        const base64Data = captureCanvas.toDataURL('image/jpeg', 0.85);
        document.getElementById(hiddenInputId).value = base64Data;
        
        previewImgElement.src = base64Data;
        previewImgElement.style.display = 'block';
        videoElement.style.display = 'none';
        
        return base64Data;
    }

    // Step 4 Portrait Camera Event Listeners
    document.getElementById('btn-capture-portrait').addEventListener('click', () => {
        const video = document.getElementById('portrait-video');
        const preview = document.getElementById('portrait-preview');
        const captureBtn = document.getElementById('btn-capture-portrait');
        const retakeBtn = document.getElementById('btn-retake-portrait');

        const data = captureSnapshot(video, preview, 'portrait_data');
        if (data) {
            stopStream(portraitStream);
            portraitStream = null;
            captureBtn.style.display = 'none';
            retakeBtn.style.display = 'inline-block';
        }
    });

    document.getElementById('btn-retake-portrait').addEventListener('click', async () => {
        const video = document.getElementById('portrait-video');
        const preview = document.getElementById('portrait-preview');
        const captureBtn = document.getElementById('btn-capture-portrait');
        const retakeBtn = document.getElementById('btn-retake-portrait');

        preview.style.display = 'none';
        video.style.display = 'block';
        captureBtn.style.display = 'inline-block';
        retakeBtn.style.display = 'none';
        document.getElementById('portrait_data').value = '';
        
        portraitStream = await startCamera(video);
    });

    // Step 5 KYC Docs Event Listeners (PAN)
    document.getElementById('btn-capture-pan').addEventListener('click', () => {
        const video = document.getElementById('pan-video');
        const preview = document.getElementById('pan-preview');
        const captureBtn = document.getElementById('btn-capture-pan');
        const retakeBtn = document.getElementById('btn-retake-pan');

        const data = captureSnapshot(video, preview, 'doc_pan_data');
        if (data) {
            stopStream(panStream);
            panStream = null;
            captureBtn.style.display = 'none';
            retakeBtn.style.display = 'inline-block';
        }
    });

    document.getElementById('btn-retake-pan').addEventListener('click', async () => {
        const video = document.getElementById('pan-video');
        const preview = document.getElementById('pan-preview');
        const captureBtn = document.getElementById('btn-capture-pan');
        const retakeBtn = document.getElementById('btn-retake-pan');

        preview.style.display = 'none';
        video.style.display = 'block';
        captureBtn.style.display = 'inline-block';
        retakeBtn.style.display = 'none';
        document.getElementById('doc_pan_data').value = '';

        panStream = await startCamera(video);
    });

    // Step 5 KYC Docs Event Listeners (Aadhaar)
    document.getElementById('btn-capture-aadhaar').addEventListener('click', () => {
        const video = document.getElementById('aadhaar-video');
        const preview = document.getElementById('aadhaar-preview');
        const captureBtn = document.getElementById('btn-capture-aadhaar');
        const retakeBtn = document.getElementById('btn-retake-aadhaar');

        const data = captureSnapshot(video, preview, 'doc_aadhaar_data');
        if (data) {
            stopStream(aadhaarStream);
            aadhaarStream = null;
            captureBtn.style.display = 'none';
            retakeBtn.style.display = 'inline-block';
        }
    });

    document.getElementById('btn-retake-aadhaar').addEventListener('click', async () => {
        const video = document.getElementById('aadhaar-video');
        const preview = document.getElementById('aadhaar-preview');
        const captureBtn = document.getElementById('btn-capture-aadhaar');
        const retakeBtn = document.getElementById('btn-retake-aadhaar');

        preview.style.display = 'none';
        video.style.display = 'block';
        captureBtn.style.display = 'inline-block';
        retakeBtn.style.display = 'none';
        document.getElementById('doc_aadhaar_data').value = '';

        aadhaarStream = await startCamera(video);
    });


    /* --- Navigation Wizards --- */

    btnNext.addEventListener('click', async () => {
        if (validateStep(currentStep)) {
            // Stop streams from previous steps if leaving
            handleStepTransitionOut(currentStep);
            
            currentStep++;
            updateStepView();
            
            // Start streams or initialize elements for next step
            await handleStepTransitionIn(currentStep);
        }
    });

    btnBack.addEventListener('click', async () => {
        handleStepTransitionOut(currentStep);
        
        currentStep--;
        updateStepView();
        
        await handleStepTransitionIn(currentStep);
    });

    function validateStep(step) {
        errorAlert.style.display = 'none';
        
        const activeSection = document.getElementById(`sec-step-${step}`);
        const inputs = activeSection.querySelectorAll('input[required], select[required], textarea[required]');
        
        // Form validations for Step 1 and 2
        for (let input of inputs) {
            if (!input.value.trim()) {
                showValidationError(`Please complete all required fields. "${input.previousElementSibling ? input.previousElementSibling.textContent : 'Field'}" is missing.`);
                input.focus();
                return false;
            }
        }

        // Custom validation for Step 3 (Signature)
        if (step === 3) {
            if (!isSignatureDrawn) {
                showValidationError("Please draw your signature on the board to proceed.");
                return false;
            }
            // Save signature data
            document.getElementById('signature_data').value = canvas.toDataURL('image/png');
        }

        // Custom validation for Step 4 (Portrait)
        if (step === 4) {
            const portrait = document.getElementById('portrait_data').value;
            if (!portrait) {
                showValidationError("Please take a live portrait photo using your camera before continuing.");
                return false;
            }
        }

        // Custom validation for Step 5 (KYC Documents)
        if (step === 5) {
            const pan = document.getElementById('doc_pan_data').value;
            const aadhaar = document.getElementById('doc_aadhaar_data').value;
            if (!pan || !aadhaar) {
                showValidationError("Please capture both your PAN Card and Aadhaar Card documents.");
                return false;
            }
        }

        return true;
    }

    function showValidationError(msg) {
        errorAlert.textContent = msg;
        errorAlert.style.display = 'block';
        window.scrollTo({ top: 0, behavior: 'smooth' });
    }

    function updateStepView() {
        // Toggle step section active states
        document.querySelectorAll('.step-section').forEach(sec => {
            sec.classList.remove('active');
        });
        document.getElementById(`sec-step-${currentStep}`).classList.add('active');

        // Toggle progress bar dot states
        document.querySelectorAll('.step-item').forEach((item, index) => {
            const stepNum = index + 1;
            item.classList.remove('active', 'completed');
            
            if (stepNum === currentStep) {
                item.classList.add('active');
            } else if (stepNum < currentStep) {
                item.classList.add('completed');
            }
        });

        // Toggle button states
        btnBack.style.display = currentStep > 1 ? 'block' : 'none';
        btnNext.style.display = currentStep < 6 ? 'block' : 'none';
        btnSubmit.style.display = currentStep === 6 ? 'block' : 'none';

        // Scroll page to top
        window.scrollTo({ top: 0, behavior: 'smooth' });
    }

    function handleStepTransitionOut(step) {
        if (step === 4) {
            stopStream(portraitStream);
            portraitStream = null;
        } else if (step === 5) {
            stopStream(panStream);
            stopStream(aadhaarStream);
            panStream = null;
            aadhaarStream = null;
        }
    }

    async function handleStepTransitionIn(step) {
        if (step === 3) {
            // Re-render canvas dimensions in case layout shifted
            setTimeout(resizeCanvas, 100);
        } else if (step === 4) {
            // Portrait camera initialization
            const portraitPreview = document.getElementById('portrait_data').value;
            if (!portraitPreview) {
                portraitStream = await startCamera(document.getElementById('portrait-video'));
            }
        } else if (step === 5) {
            // PAN & Aadhaar cameras initialization
            const panVal = document.getElementById('doc_pan_data').value;
            if (!panVal) {
                panStream = await startCamera(document.getElementById('pan-video'));
            }
            const aadhaarVal = document.getElementById('doc_aadhaar_data').value;
            if (!aadhaarVal) {
                aadhaarStream = await startCamera(document.getElementById('aadhaar-video'));
            }
        } else if (step === 6) {
            // Load review summaries
            compileReviewSummary();
        }
    }

    function compileReviewSummary() {
        document.getElementById('rev-full-name').textContent = document.getElementById('full_name').value;
        document.getElementById('rev-email').textContent = document.getElementById('email').value;
        document.getElementById('rev-phone').textContent = document.getElementById('phone').value;
        document.getElementById('rev-address').textContent = document.getElementById('address').value;
        document.getElementById('rev-national-id').textContent = document.getElementById('national_id').value;

        if (accountType === 'VEHICLE') {
            document.getElementById('rev-dob').textContent = document.getElementById('dob').value;
            document.getElementById('rev-gender').textContent = document.getElementById('gender').value;
            document.getElementById('rev-initial-deposit').textContent = parseFloat(document.getElementById('initial_deposit').value).toLocaleString() + ' INR';
        } else {
            document.getElementById('rev-business-name').textContent = document.getElementById('business_name').value;
            document.getElementById('rev-business-reg').textContent = document.getElementById('business_reg_no').value;
            document.getElementById('rev-turnover').textContent = parseFloat(document.getElementById('expected_turnover').value).toLocaleString() + ' INR';
        }

        // Assets previews
        document.getElementById('rev-img-portrait').src = document.getElementById('portrait_data').value;
        document.getElementById('rev-img-sig').src = document.getElementById('signature_data').value;
        document.getElementById('rev-img-pan').src = document.getElementById('doc_pan_data').value;
        document.getElementById('rev-img-aadhaar').src = document.getElementById('doc_aadhaar_data').value;
    }

    /* --- Form Submission (AJAX POST) --- */

    btnSubmit.addEventListener('click', () => {
        submitApplicationToServer();
    });

    function submitApplicationToServer() {
        errorAlert.style.display = 'none';
        btnSubmit.setAttribute('disabled', 'disabled');
        btnSubmit.textContent = 'Submitting Application...';

        const formData = new FormData(form);
        const data = {};
        formData.forEach((value, key) => {
            data[key] = value;
        });

        fetch('api/submit.php', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(data)
        })
        .then(response => response.json())
        .then(res => {
            btnSubmit.removeAttribute('disabled');
            btnSubmit.textContent = 'Submit Application';

            if (res.success) {
                // Success redirect inside page wizard
                document.getElementById('lbl-app-id').textContent = res.app_id;
                
                // Hide steps & footer
                document.querySelector('.step-progress-bar').style.display = 'none';
                footerActions.style.display = 'none';
                
                // Display step 7 (Success)
                document.querySelectorAll('.step-section').forEach(sec => {
                    sec.classList.remove('active');
                });
                document.getElementById('sec-step-7').classList.add('active');
            } else {
                showValidationError(res.message || 'An error occurred during application processing.');
            }
        })
        .catch(err => {
            btnSubmit.removeAttribute('disabled');
            btnSubmit.textContent = 'Submit Application';
            showValidationError('Network error: Failed to reach Deccan Finance servers.');
        });
    }
});

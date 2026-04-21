let primaryPhotoRadioHandler;

const syncPrimaryPhotoGroup = (selectedRadio) => {
  if (!selectedRadio?.checked) return;

  const group = selectedRadio.dataset.primaryPhotoGroup;
  if (!group) return;

  document.querySelectorAll('[data-primary-photo-radio="true"]').forEach((radio) => {
    if (radio === selectedRadio) return;
    if (radio.dataset.primaryPhotoGroup !== group) return;

    radio.checked = false;
  });
};

export const bootPhotoPrimaryRadios = () => {
  if (primaryPhotoRadioHandler) return;

  primaryPhotoRadioHandler = (event) => {
    const radio = event.target.closest?.('[data-primary-photo-radio="true"]');
    if (!radio) return;

    syncPrimaryPhotoGroup(radio);
  };

  document.addEventListener("change", primaryPhotoRadioHandler);
};

export const teardownPhotoPrimaryRadios = () => {};

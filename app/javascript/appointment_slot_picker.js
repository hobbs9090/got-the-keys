const pickerState = new WeakMap();

const parseSlots = (picker) => {
  const source = picker.querySelector("[data-slot-picker-source]");
  if (!source) return [];

  try {
    return JSON.parse(source.textContent);
  } catch (_error) {
    return [];
  }
};

const summaryForValue = (slots, value) => {
  for (const day of slots) {
    const match = day.times.find((time) => time.value === value);
    if (match) return `${day.label} · ${match.label}`;
  }

  return null;
};

const setSelectedDate = (picker, dateKey) => {
  picker.querySelectorAll("[data-slot-picker-date]").forEach((button) => {
    const selected = button.dataset.slotPickerDate === dateKey;
    button.classList.toggle("is-selected", selected);
    button.setAttribute("aria-selected", selected ? "true" : "false");
  });

  picker.querySelectorAll("[data-slot-picker-time-group]").forEach((group) => {
    const active = group.dataset.slotPickerTimeGroup === dateKey;
    group.classList.toggle("is-active", active);
    group.hidden = !active;
  });
};

const setSelectedTime = (picker, value) => {
  const input = picker.querySelector("[data-slot-picker-input]");
  if (input) input.value = value || "";

  picker.querySelectorAll("[data-slot-picker-time]").forEach((button) => {
    button.classList.toggle("is-selected", button.dataset.slotPickerTime === value);
  });

  const state = pickerState.get(picker);
  const summary = picker.querySelector("[data-slot-picker-summary]");
  if (summary && state) {
    summary.innerHTML = value && summaryForValue(state.slots, value)
      ? `<strong>${summaryForValue(state.slots, value)}</strong>`
      : state.emptySummary;
  }
};

const bindPicker = (picker) => {
  if (pickerState.has(picker)) return;

  const slots = parseSlots(picker);
  const input = picker.querySelector("[data-slot-picker-input]");
  const emptySummary = picker.querySelector("[data-slot-picker-summary]")?.textContent || "";

  if (!input || slots.length === 0) return;

  const selectedValue = input.value;
  const selectedDay = slots.find((day) => day.times.some((time) => time.value === selectedValue)) || slots[0];
  const cleanup = [];

  picker.querySelectorAll("[data-slot-picker-date]").forEach((button) => {
    button.disabled = false;

    const handleClick = () => {
      const selectedTimeForDay = slots
        .find((day) => day.key === button.dataset.slotPickerDate)
        ?.times.some((time) => time.value === input.value);

      setSelectedDate(picker, button.dataset.slotPickerDate);
      if (!selectedTimeForDay) setSelectedTime(picker, "");

      const activeGroup = picker.querySelector("[data-slot-picker-time-group].is-active");
      activeGroup?.scrollIntoView({ behavior: "smooth", block: "nearest" });
    };

    button.addEventListener("click", handleClick);
    cleanup.push([button, handleClick]);
  });

  picker.querySelectorAll("[data-slot-picker-time]").forEach((button) => {
    button.disabled = false;

    const handleClick = () => {
      setSelectedDate(picker, button.dataset.slotPickerDateKey);
      setSelectedTime(picker, button.dataset.slotPickerTime);
    };

    button.addEventListener("click", handleClick);
    cleanup.push([button, handleClick]);
  });

  pickerState.set(picker, { cleanup, slots, emptySummary });
  setSelectedDate(picker, selectedDay.key);
  setSelectedTime(picker, selectedValue || "");
};

export const bootAppointmentSlotPickers = () => {
  document.querySelectorAll("[data-slot-picker]").forEach(bindPicker);
};

export const teardownAppointmentSlotPickers = () => {
  document.querySelectorAll("[data-slot-picker]").forEach((picker) => {
    const state = pickerState.get(picker);
    if (!state) return;

    state.cleanup.forEach(([element, handler]) => {
      element.removeEventListener("click", handler);
    });

    pickerState.delete(picker);
  });
};

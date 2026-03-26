let resizeHandler;
let splitTables = new WeakSet();

const setCellHeights = (original, copy) => {
  const heights = [];

  original.querySelectorAll("tr").forEach((row, index) => {
    row.querySelectorAll("th, td").forEach((cell) => {
      const height = cell.getBoundingClientRect().height;
      heights[index] = Math.max(heights[index] || 0, height);
    });
  });

  copy.querySelectorAll("tr").forEach((row, index) => {
    row.style.height = `${heights[index] || 0}px`;
  });
};

const splitTable = (table) => {
  if (table.closest(".table-wrapper")) return;

  const wrapper = document.createElement("div");
  wrapper.className = "table-wrapper";
  table.parentNode.insertBefore(wrapper, table);
  wrapper.appendChild(table);

  const pinned = document.createElement("div");
  pinned.className = "pinned";

  const scrollable = document.createElement("div");
  scrollable.className = "scrollable";

  const copy = table.cloneNode(true);
  copy.classList.remove("responsive");
  copy.querySelectorAll("td:not(:first-child), th:not(:first-child)").forEach((cell) => {
    cell.style.display = "none";
  });

  wrapper.appendChild(pinned);
  wrapper.appendChild(scrollable);
  pinned.appendChild(copy);
  scrollable.appendChild(table);

  setCellHeights(table, copy);
  splitTables.add(table);
};

const unsplitTable = (table) => {
  const wrapper = table.closest(".table-wrapper");
  if (!wrapper) return;

  const parent = wrapper.parentNode;
  parent.insertBefore(table, wrapper);
  wrapper.remove();
};

const updateTables = () => {
  const shouldSplit = window.innerWidth < 767;

  document.querySelectorAll("table.responsive").forEach((table) => {
    if (shouldSplit) {
      splitTable(table);
    } else if (splitTables.has(table)) {
      unsplitTable(table);
      splitTables.delete(table);
    }
  });
};

export const bootResponsiveTables = () => {
  if (!resizeHandler) {
    resizeHandler = () => updateTables();
    window.addEventListener("resize", resizeHandler);
  }

  updateTables();
};

export const teardownResponsiveTables = () => {
  document.querySelectorAll("table.responsive").forEach((table) => {
    if (splitTables.has(table)) {
      unsplitTable(table);
      splitTables.delete(table);
    }
  });

  if (resizeHandler) {
    window.removeEventListener("resize", resizeHandler);
    resizeHandler = null;
  }
};

const modal = document.getElementById("modal");
const modalImage = document.getElementById("modal-image");

function dismiss() {
	modal.style.display = "none";
	modalImage.src = "";
}

modal.onclick = dismiss

function showImage(src) {
	modal.style.display = "block";
	modalImage.src = src;
}

for (const classname of ["tutorial-image", "tutorial-image-noshadow"]) {
	for (const img of document.getElementsByClassName(classname)) {
		img.onclick = () => {
			showImage(img.src);
		}
	}
}
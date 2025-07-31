from PIL import Image, UnidentifiedImageError
import os
import sys
import json
import logging
import argparse


def generate_zoom_frames(input_path: str, output_dir: str, total_frames: int = 150, zoom_factor_per_frame: float = 0.001, canvas_size: tuple[int, int] = (1080, 1920)):
	"""
	Generates a sequence of zoomed-in frames from a source image.

	Args:
		input_path (str): Path to the source image.
		output_dir (str): Directory to save the generated frames.
		total_frames (int): The total number of frames to generate.
		zoom_factor_per_frame (float): The zoom increment for each frame.
		canvas_size (tuple): The (width, height) of the output frames.

	Raises:
		FileNotFoundError: If the input file does not exist.
		IsADirectoryError: If the input path is a directory.
		UnidentifiedImageError: If the input file is not a valid image.
		PermissionError: If the output directory cannot be created or written to.
		IOError: If a frame cannot be saved.
		Exception: For other image processing errors.
	"""
	# --- Input Validation ---
	if not os.path.exists(input_path):
		raise FileNotFoundError(f"Input file not found: {input_path}")
	if not os.path.isfile(input_path):
		raise IsADirectoryError(f"Input path is a directory, not a file: {input_path}")

	try:
		logging.debug(f"Opening image: {input_path}")
		img = Image.open(input_path)
	except UnidentifiedImageError:
		raise UnidentifiedImageError(f"Cannot identify image file: {input_path}. It may be corrupt or an unsupported format.")
	except Exception as e:
		raise Exception(f"Error opening image file {input_path}: {e}")

	img = img.convert("RGB")  # Ensure image is in RGB format

	# --- Output Directory Validation ---
	try:
		os.makedirs(output_dir, exist_ok=True)
		if not os.access(output_dir, os.W_OK):
			raise PermissionError(f"Output directory is not writable: {output_dir}")
	except OSError as e:
		raise PermissionError(f"Error creating output directory {output_dir}: {e}")

	logging.debug(f"Generating {total_frames} frames into '{output_dir}'...")

	# --- Image Processing ---
	# Resize and crop to fit canvas
	img_ratio = img.width / img.height
	canvas_ratio = canvas_size[0] / canvas_size[1]

	if img_ratio > canvas_ratio:
		new_height = canvas_size[1]
		new_width = int(img_ratio * new_height)
	else:
		new_width = canvas_size[0]
		new_height = int(new_width / img_ratio)

	img = img.resize((new_width, new_height), Image.LANCZOS)

	left = (new_width - canvas_size[0]) // 2
	top = (new_height - canvas_size[1]) // 2
	img = img.crop((left, top, left + canvas_size[0], top + canvas_size[1]))

	# --- Frame Generation ---
	# This variable will hold the last generated frame to be used for the hold sequence.
	last_frame = None
	for i in range(total_frames):
		zoom = 1 + zoom_factor_per_frame * i
		crop_width = int(canvas_size[0] / zoom)
		crop_height = int(canvas_size[1] / zoom)

		x1 = (canvas_size[0] - crop_width) // 2
		y1 = (canvas_size[1] - crop_height) // 2

		frame = img.crop((x1, y1, x1 + crop_width, y1 + crop_height))
		frame = frame.resize(canvas_size, Image.LANCZOS)
		last_frame = frame  # Keep track of the last frame

		output_path = os.path.join(output_dir, f"frame_{i:04d}.png")
		try:
			frame.save(output_path)
		except Exception as e:
			raise IOError(f"Error saving frame {output_path}: {e}")

	# --- Hold Frames Generation ---
	# Add 150 static frames that are copies of the last zoomed frame.
	if last_frame:
		hold_frames = total_frames + 60
		logging.debug(f"Adding {hold_frames} static hold frames...")
		for j in range(hold_frames):
			# Frame numbering continues from where the zoom sequence left off.
			frame_num = total_frames + j
			output_path = os.path.join(output_dir, f"frame_{frame_num:04d}.png")
			try:
				last_frame.save(output_path)
			except Exception as e:
				raise IOError(f"Error saving hold frame {output_path}: {e}")


def main():
	"""
	Main function to parse command-line arguments and run the frame generation.
	"""
	parser = argparse.ArgumentParser(
		description="Generate a sequence of zoom-in frames from a source image.",
		formatter_class=argparse.RawTextHelpFormatter
	)
	parser.add_argument('--input_frame', required=True, help='Path to the input image file.')
	parser.add_argument('--output_frames_dir', required=True, help='Path to the directory to save output frames.')

	args = parser.parse_args()

	# Configure logging to output to stderr. By default, only WARNING level and above will be shown.
	# Debug messages are suppressed unless the logging level is changed.
	logging.basicConfig(level=logging.WARNING, stream=sys.stderr, format='%(levelname)s: %(message)s')

	try:
		generate_zoom_frames(args.input_frame, args.output_frames_dir)
		output_data = {
			"framesPath": args.output_frames_dir,
			"inputImagePath": args.input_frame
		}
		print(json.dumps(output_data, indent=2))
	except (FileNotFoundError, IsADirectoryError, UnidentifiedImageError, PermissionError, IOError) as e:
		logging.error(e)
		sys.exit(1)
	except Exception as e:
		logging.error(f"An unexpected error occurred: {e}")
		sys.exit(1)


if __name__ == "__main__":
	main()

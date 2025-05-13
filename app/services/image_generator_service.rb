require 'mini_magick'
require 'open-uri'

class ImageGeneratorService
  def self.generate(submission)
    return if submission.nil? || submission.generated_image_path.present?

    # Create a new image with white background
    image = MiniMagick::Image.new(MiniMagick::Image.open("public/placeholder-book.svg").path)
    image.combine_options do |c|
      c.size "1200x630"
      c.background "white"
      c.gravity "center"
      c.extent "1200x630"
    end

    # Download and process each book cover
    book_images = []
    submission.submission_books.order(:book_order).each do |book|
      begin
        temp_image = MiniMagick::Image.open(book.cover_url)
        temp_image.resize "300x450"
        book_images << temp_image
      rescue => e
        Rails.logger.error "Failed to process book cover: #{e.message}"
        # Use placeholder if cover download fails
        temp_image = MiniMagick::Image.open("public/placeholder-book.svg")
        temp_image.resize "300x450"
        book_images << temp_image
      end
    end

    # Combine images horizontally with padding
    result = MiniMagick::Image.new(image.path)
    result.combine_options do |c|
      c.size "1200x630"
      c.background "white"
      c.gravity "center"
      
      # Calculate positions for 3 books
      x_positions = [-350, 0, 350]
      book_images.each_with_index do |book_image, index|
        c.draw "image Over #{x_positions[index]},-50 0,0 '#{book_image.path}'"
      end
      
      # Add hashtag
      c.font "Arial"
      c.pointsize "36"
      c.fill "#333333"
      c.draw "text 0,250 '#3books-changed-me'"
    end

    # Save the generated image
    timestamp = Time.current.strftime("%Y%m%d%H%M%S")
    filename = "submission_#{submission.uuid}_#{timestamp}.jpg"
    
    # Ensure directory exists
    FileUtils.mkdir_p(Rails.root.join("public/generated"))
    image_path = Rails.root.join("public/generated/#{filename}")
    
    result.write(image_path)

    # Update submission with the image path
    submission.update!(generated_image_path: "/generated/#{filename}")
    
    "/generated/#{filename}"
  end
end

package com.project.shopapp.services.product.image;

import com.project.shopapp.exceptions.DataNotFoundException;
import com.project.shopapp.models.Product;
import com.project.shopapp.models.ProductImage;
import com.project.shopapp.repositories.ProductImageRepository;
import com.project.shopapp.repositories.ProductRepository;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class ProductImageService implements IProductImageService{
    private final ProductImageRepository productImageRepository;
    private final ProductRepository productRepository;
    @Override
    @Transactional
    public ProductImage deleteProductImage(Long id) {
        Optional<ProductImage> imageOptional = productImageRepository.findById(id);
        if (imageOptional.isEmpty()) {
            throw new RuntimeException("Image not found with id: " + id);
        }

        ProductImage image = imageOptional.get();
        Product product = image.getProduct();

        productImageRepository.deleteById(id);

        if (image.getImageUrl().equals(product.getThumbnail())) {
            List<ProductImage> remainingImages = productImageRepository.findByProductId(product.getId());

            if (!remainingImages.isEmpty()) {
                product.setThumbnail(remainingImages.get(0).getImageUrl());
            } else {
                product.setThumbnail(null);
            }

            productRepository.save(product);
        }
        return image;
    }

}

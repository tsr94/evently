package com.tsr.tickets.services.implt;

import com.google.zxing.BarcodeFormat;
import com.google.zxing.WriterException;
import com.google.zxing.client.j2se.MatrixToImageWriter;
import com.google.zxing.common.BitMatrix;
import com.google.zxing.qrcode.QRCodeWriter;
import com.tsr.tickets.domain.entity.QrCode;
import com.tsr.tickets.domain.entity.QrCodeStatusEnum;
import com.tsr.tickets.domain.entity.Ticket;
import com.tsr.tickets.exceptions.QrCodeGenerationException;
import com.tsr.tickets.exceptions.QrCodeNotFoundException;
import com.tsr.tickets.repository.QrCodeRepository;
import com.tsr.tickets.services.QrCodeService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.Base64;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class QrCodeServiceImpl implements QrCodeService {
    private static final int QR_HEIGHT = 300;
    private static final int QR_WIDTH = 300;

    private final QRCodeWriter qrCodeWriter;
    private final QrCodeRepository qrCodeRepository;

    @Override
    public QrCode generateQrCode(Ticket ticket) {
        try {
            // Generate a unique ID for the QR code
            UUID uniqueId = UUID.randomUUID();
            String qrCodeImage = generateQrCodeImage(uniqueId);

            // Create and save the QR code entity
            QrCode qrCode = new QrCode();
            qrCode.setId(uniqueId);
            qrCode.setStatus(QrCodeStatusEnum.ACTIVE);
            qrCode.setValue(qrCodeImage);
            qrCode.setTicket(ticket);

            return qrCodeRepository.saveAndFlush(qrCode);
        } catch(IOException | WriterException ex) {
            throw new QrCodeGenerationException("Failed to generate QR Code", ex);
        }
    }

    @Override
    public byte[] getQrCodeImageForUserAndTicket(UUID userId, UUID ticketId) {

        QrCode qrCode = qrCodeRepository.findByTicketIdAndTicketPurchaserId(ticketId, userId)
                .orElseThrow(QrCodeNotFoundException::new);

        try {
            return Base64.getDecoder().decode(qrCode.getValue());
        }
     catch(IllegalArgumentException ex) {
                log.error("Invalid base64 QR Code for ticket ID: {}", ticketId, ex);
                throw new QrCodeNotFoundException();
            }

    }

    private String generateQrCodeImage(UUID uniqueId)
            throws WriterException, IOException {


        // Create a BitMatrix representing the QR code.
        //
        // BitMatrix is basically a grid of true/false values
        // representing the black and white QR-code pixels.
        //
        // Example conceptually:
        //
        // 101010101
        // 110010011
        // 001101100
        // ...
        //
        // encode() receives:
        //
        // 1. uniqueId.toString()
        //    → Data that will be stored inside the QR code.
        //
        // 2. BarcodeFormat.QR_CODE
        //    → Tell ZXing that we want a QR code.
        //
        // 3. QR_WIDTH
        //    → Width = 300 pixels.
        //
        // 4. QR_HEIGHT
        //    → Height = 300 pixels.
        BitMatrix bitMatrix = qrCodeWriter.encode(
                uniqueId.toString(),
                BarcodeFormat.QR_CODE,
                QR_WIDTH,
                QR_HEIGHT
        );


        // Convert the BitMatrix into an actual image.
        //
        // BitMatrix:
        //     QR pattern/grid
        //
        // BufferedImage:
        //     Actual image that Java can work with.
        BufferedImage qrCodeImage =
                MatrixToImageWriter.toBufferedImage(bitMatrix);


        // Create an in-memory output stream.
        //
        // Instead of writing the PNG image to a file on disk,
        // we keep it in memory.
        //
        // try-with-resources automatically closes baos
        // when this block finishes.
        try (ByteArrayOutputStream baos =
                     new ByteArrayOutputStream()) {


            // Convert the BufferedImage into PNG format
            // and write the PNG bytes into baos.
            //
            // qrCodeImage → PNG → bytes
            //
            // The bytes are stored in memory.
            ImageIO.write(
                    qrCodeImage,
                    "PNG",
                    baos
            );


            // Get the raw PNG image bytes from the output stream.
            //
            // Example conceptually:
            //
            // [137, 80, 78, 71, 13, 10, ...]
            byte[] imageBytes = baos.toByteArray();


            // Convert binary image bytes into Base64 text.
            //
            // Why?
            //
            // Database fields are easier to store/transmit as text.
            //
            // Binary PNG:
            //     [137, 80, 78, 71, ...]
            //
            // becomes:
            //     iVBORw0KGgoAAAANSUhEUg...
            //
            // This Base64 String is returned.
            return Base64.getEncoder()
                    .encodeToString(imageBytes);
        }
    }
}

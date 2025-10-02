package com.bs.ordercmd.domain
import jakarta.persistence.*
import java.time.Instant

@Entity @Table(name = "orders")
class Order(
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null,
    val userId: Long,
    val amount: Long,
    @Enumerated(EnumType.STRING)
    var status: Status = Status.PENDING,
    val createdAt: Instant = Instant.now()
) {
    enum class Status { PENDING, CONFIRMED, CANCELLED }
    fun confirm() { status = Status.CONFIRMED }
    fun cancel() { status = Status.CANCELLED }
}

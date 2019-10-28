
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Kinesis Firehose
## version: 2015-08-04
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon Kinesis Data Firehose API Reference</fullname> <p>Amazon Kinesis Data Firehose is a fully managed service that delivers real-time streaming data to destinations such as Amazon Simple Storage Service (Amazon S3), Amazon Elasticsearch Service (Amazon ES), Amazon Redshift, and Splunk.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/firehose/
type
  Scheme {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (query: JsonNode = nil; body: JsonNode = nil;
                          header: JsonNode = nil; path: JsonNode = nil;
                          formData: JsonNode = nil): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    url*: proc (protocol: Scheme; host: string; base: string; route: string;
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_590364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_590364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_590364): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low ..
      Scheme.high:
    if scheme notin t.schemes:
      continue
    if scheme in [Scheme.Https, Scheme.Wss]:
      when defined(ssl):
        return some(scheme)
      else:
        continue
    return some(scheme)

proc validateParameter(js: JsonNode; kind: JsonNodeKind; required: bool;
                      default: JsonNode = nil): JsonNode =
  ## ensure an input is of the correct json type and yield
  ## a suitable default value when appropriate
  if js ==
      nil:
    if default != nil:
      return validateParameter(default, kind, required = required)
  result = js
  if result ==
      nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind ==
        kind, $kind & " expected; received " &
        $js.kind

type
  KeyVal {.used.} = tuple[key: string, val: string]
  PathTokenKind = enum
    ConstantSegment, VariableSegment
  PathToken = tuple[kind: PathTokenKind, value: string]
proc queryString(query: JsonNode): string {.used.} =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.used.} =
  ## reconstitute a path with constants and variable values taken from json
  var head: string
  if segments.len == 0:
    return some("")
  head = segments[0].value
  case segments[0].kind
  of ConstantSegment:
    discard
  of VariableSegment:
    if head notin input:
      return
    let js = input[head]
    case js.kind
    of JInt, JFloat, JNull, JBool:
      head = $js
    of JString:
      head = js.getStr
    else:
      return
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get)

const
  awsServers = {Scheme.Http: {"ap-northeast-1": "firehose.ap-northeast-1.amazonaws.com", "ap-southeast-1": "firehose.ap-southeast-1.amazonaws.com",
                           "us-west-2": "firehose.us-west-2.amazonaws.com",
                           "eu-west-2": "firehose.eu-west-2.amazonaws.com", "ap-northeast-3": "firehose.ap-northeast-3.amazonaws.com", "eu-central-1": "firehose.eu-central-1.amazonaws.com",
                           "us-east-2": "firehose.us-east-2.amazonaws.com",
                           "us-east-1": "firehose.us-east-1.amazonaws.com", "cn-northwest-1": "firehose.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "firehose.ap-south-1.amazonaws.com",
                           "eu-north-1": "firehose.eu-north-1.amazonaws.com", "ap-northeast-2": "firehose.ap-northeast-2.amazonaws.com",
                           "us-west-1": "firehose.us-west-1.amazonaws.com", "us-gov-east-1": "firehose.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "firehose.eu-west-3.amazonaws.com", "cn-north-1": "firehose.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "firehose.sa-east-1.amazonaws.com",
                           "eu-west-1": "firehose.eu-west-1.amazonaws.com", "us-gov-west-1": "firehose.us-gov-west-1.amazonaws.com", "ap-southeast-2": "firehose.ap-southeast-2.amazonaws.com", "ca-central-1": "firehose.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "firehose.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "firehose.ap-southeast-1.amazonaws.com",
      "us-west-2": "firehose.us-west-2.amazonaws.com",
      "eu-west-2": "firehose.eu-west-2.amazonaws.com",
      "ap-northeast-3": "firehose.ap-northeast-3.amazonaws.com",
      "eu-central-1": "firehose.eu-central-1.amazonaws.com",
      "us-east-2": "firehose.us-east-2.amazonaws.com",
      "us-east-1": "firehose.us-east-1.amazonaws.com",
      "cn-northwest-1": "firehose.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "firehose.ap-south-1.amazonaws.com",
      "eu-north-1": "firehose.eu-north-1.amazonaws.com",
      "ap-northeast-2": "firehose.ap-northeast-2.amazonaws.com",
      "us-west-1": "firehose.us-west-1.amazonaws.com",
      "us-gov-east-1": "firehose.us-gov-east-1.amazonaws.com",
      "eu-west-3": "firehose.eu-west-3.amazonaws.com",
      "cn-north-1": "firehose.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "firehose.sa-east-1.amazonaws.com",
      "eu-west-1": "firehose.eu-west-1.amazonaws.com",
      "us-gov-west-1": "firehose.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "firehose.ap-southeast-2.amazonaws.com",
      "ca-central-1": "firehose.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "firehose"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateDeliveryStream_590703 = ref object of OpenApiRestCall_590364
proc url_CreateDeliveryStream_590705(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDeliveryStream_590704(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a Kinesis Data Firehose delivery stream.</p> <p>By default, you can create up to 50 delivery streams per AWS Region.</p> <p>This is an asynchronous operation that immediately returns. The initial status of the delivery stream is <code>CREATING</code>. After the delivery stream is created, its status is <code>ACTIVE</code> and it now accepts data. Attempts to send data to a delivery stream that is not in the <code>ACTIVE</code> state cause an exception. To check the state of a delivery stream, use <a>DescribeDeliveryStream</a>.</p> <p>A Kinesis Data Firehose delivery stream can be configured to receive records directly from providers using <a>PutRecord</a> or <a>PutRecordBatch</a>, or it can be configured to use an existing Kinesis stream as its source. To specify a Kinesis data stream as input, set the <code>DeliveryStreamType</code> parameter to <code>KinesisStreamAsSource</code>, and provide the Kinesis stream Amazon Resource Name (ARN) and role ARN in the <code>KinesisStreamSourceConfiguration</code> parameter.</p> <p>A delivery stream is configured with a single destination: Amazon S3, Amazon ES, Amazon Redshift, or Splunk. You must specify only one of the following destination configuration parameters: <code>ExtendedS3DestinationConfiguration</code>, <code>S3DestinationConfiguration</code>, <code>ElasticsearchDestinationConfiguration</code>, <code>RedshiftDestinationConfiguration</code>, or <code>SplunkDestinationConfiguration</code>.</p> <p>When you specify <code>S3DestinationConfiguration</code>, you can also provide the following optional values: BufferingHints, <code>EncryptionConfiguration</code>, and <code>CompressionFormat</code>. By default, if no <code>BufferingHints</code> value is provided, Kinesis Data Firehose buffers data up to 5 MB or for 5 minutes, whichever condition is satisfied first. <code>BufferingHints</code> is a hint, so there are some cases where the service cannot adhere to these conditions strictly. For example, record boundaries might be such that the size is a little over or under the configured buffering size. By default, no encryption is performed. We strongly recommend that you enable encryption to ensure secure data storage in Amazon S3.</p> <p>A few notes about Amazon Redshift as a destination:</p> <ul> <li> <p>An Amazon Redshift destination requires an S3 bucket as intermediate location. Kinesis Data Firehose first delivers data to Amazon S3 and then uses <code>COPY</code> syntax to load data into an Amazon Redshift table. This is specified in the <code>RedshiftDestinationConfiguration.S3Configuration</code> parameter.</p> </li> <li> <p>The compression formats <code>SNAPPY</code> or <code>ZIP</code> cannot be specified in <code>RedshiftDestinationConfiguration.S3Configuration</code> because the Amazon Redshift <code>COPY</code> operation that reads from the S3 bucket doesn't support these compression formats.</p> </li> <li> <p>We strongly recommend that you use the user name and password you provide exclusively with Kinesis Data Firehose, and that the permissions for the account are restricted for Amazon Redshift <code>INSERT</code> permissions.</p> </li> </ul> <p>Kinesis Data Firehose assumes the IAM role that is configured as part of the destination. The role should allow the Kinesis Data Firehose principal to assume the role, and the role should have permissions that allow the service to deliver the data. For more information, see <a href="https://docs.aws.amazon.com/firehose/latest/dev/controlling-access.html#using-iam-s3">Grant Kinesis Data Firehose Access to an Amazon S3 Destination</a> in the <i>Amazon Kinesis Data Firehose Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_590830 = header.getOrDefault("X-Amz-Target")
  valid_590830 = validateParameter(valid_590830, JString, required = true, default = newJString(
      "Firehose_20150804.CreateDeliveryStream"))
  if valid_590830 != nil:
    section.add "X-Amz-Target", valid_590830
  var valid_590831 = header.getOrDefault("X-Amz-Signature")
  valid_590831 = validateParameter(valid_590831, JString, required = false,
                                 default = nil)
  if valid_590831 != nil:
    section.add "X-Amz-Signature", valid_590831
  var valid_590832 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590832 = validateParameter(valid_590832, JString, required = false,
                                 default = nil)
  if valid_590832 != nil:
    section.add "X-Amz-Content-Sha256", valid_590832
  var valid_590833 = header.getOrDefault("X-Amz-Date")
  valid_590833 = validateParameter(valid_590833, JString, required = false,
                                 default = nil)
  if valid_590833 != nil:
    section.add "X-Amz-Date", valid_590833
  var valid_590834 = header.getOrDefault("X-Amz-Credential")
  valid_590834 = validateParameter(valid_590834, JString, required = false,
                                 default = nil)
  if valid_590834 != nil:
    section.add "X-Amz-Credential", valid_590834
  var valid_590835 = header.getOrDefault("X-Amz-Security-Token")
  valid_590835 = validateParameter(valid_590835, JString, required = false,
                                 default = nil)
  if valid_590835 != nil:
    section.add "X-Amz-Security-Token", valid_590835
  var valid_590836 = header.getOrDefault("X-Amz-Algorithm")
  valid_590836 = validateParameter(valid_590836, JString, required = false,
                                 default = nil)
  if valid_590836 != nil:
    section.add "X-Amz-Algorithm", valid_590836
  var valid_590837 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590837 = validateParameter(valid_590837, JString, required = false,
                                 default = nil)
  if valid_590837 != nil:
    section.add "X-Amz-SignedHeaders", valid_590837
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_590861: Call_CreateDeliveryStream_590703; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Kinesis Data Firehose delivery stream.</p> <p>By default, you can create up to 50 delivery streams per AWS Region.</p> <p>This is an asynchronous operation that immediately returns. The initial status of the delivery stream is <code>CREATING</code>. After the delivery stream is created, its status is <code>ACTIVE</code> and it now accepts data. Attempts to send data to a delivery stream that is not in the <code>ACTIVE</code> state cause an exception. To check the state of a delivery stream, use <a>DescribeDeliveryStream</a>.</p> <p>A Kinesis Data Firehose delivery stream can be configured to receive records directly from providers using <a>PutRecord</a> or <a>PutRecordBatch</a>, or it can be configured to use an existing Kinesis stream as its source. To specify a Kinesis data stream as input, set the <code>DeliveryStreamType</code> parameter to <code>KinesisStreamAsSource</code>, and provide the Kinesis stream Amazon Resource Name (ARN) and role ARN in the <code>KinesisStreamSourceConfiguration</code> parameter.</p> <p>A delivery stream is configured with a single destination: Amazon S3, Amazon ES, Amazon Redshift, or Splunk. You must specify only one of the following destination configuration parameters: <code>ExtendedS3DestinationConfiguration</code>, <code>S3DestinationConfiguration</code>, <code>ElasticsearchDestinationConfiguration</code>, <code>RedshiftDestinationConfiguration</code>, or <code>SplunkDestinationConfiguration</code>.</p> <p>When you specify <code>S3DestinationConfiguration</code>, you can also provide the following optional values: BufferingHints, <code>EncryptionConfiguration</code>, and <code>CompressionFormat</code>. By default, if no <code>BufferingHints</code> value is provided, Kinesis Data Firehose buffers data up to 5 MB or for 5 minutes, whichever condition is satisfied first. <code>BufferingHints</code> is a hint, so there are some cases where the service cannot adhere to these conditions strictly. For example, record boundaries might be such that the size is a little over or under the configured buffering size. By default, no encryption is performed. We strongly recommend that you enable encryption to ensure secure data storage in Amazon S3.</p> <p>A few notes about Amazon Redshift as a destination:</p> <ul> <li> <p>An Amazon Redshift destination requires an S3 bucket as intermediate location. Kinesis Data Firehose first delivers data to Amazon S3 and then uses <code>COPY</code> syntax to load data into an Amazon Redshift table. This is specified in the <code>RedshiftDestinationConfiguration.S3Configuration</code> parameter.</p> </li> <li> <p>The compression formats <code>SNAPPY</code> or <code>ZIP</code> cannot be specified in <code>RedshiftDestinationConfiguration.S3Configuration</code> because the Amazon Redshift <code>COPY</code> operation that reads from the S3 bucket doesn't support these compression formats.</p> </li> <li> <p>We strongly recommend that you use the user name and password you provide exclusively with Kinesis Data Firehose, and that the permissions for the account are restricted for Amazon Redshift <code>INSERT</code> permissions.</p> </li> </ul> <p>Kinesis Data Firehose assumes the IAM role that is configured as part of the destination. The role should allow the Kinesis Data Firehose principal to assume the role, and the role should have permissions that allow the service to deliver the data. For more information, see <a href="https://docs.aws.amazon.com/firehose/latest/dev/controlling-access.html#using-iam-s3">Grant Kinesis Data Firehose Access to an Amazon S3 Destination</a> in the <i>Amazon Kinesis Data Firehose Developer Guide</i>.</p>
  ## 
  let valid = call_590861.validator(path, query, header, formData, body)
  let scheme = call_590861.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590861.url(scheme.get, call_590861.host, call_590861.base,
                         call_590861.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590861, url, valid)

proc call*(call_590932: Call_CreateDeliveryStream_590703; body: JsonNode): Recallable =
  ## createDeliveryStream
  ## <p>Creates a Kinesis Data Firehose delivery stream.</p> <p>By default, you can create up to 50 delivery streams per AWS Region.</p> <p>This is an asynchronous operation that immediately returns. The initial status of the delivery stream is <code>CREATING</code>. After the delivery stream is created, its status is <code>ACTIVE</code> and it now accepts data. Attempts to send data to a delivery stream that is not in the <code>ACTIVE</code> state cause an exception. To check the state of a delivery stream, use <a>DescribeDeliveryStream</a>.</p> <p>A Kinesis Data Firehose delivery stream can be configured to receive records directly from providers using <a>PutRecord</a> or <a>PutRecordBatch</a>, or it can be configured to use an existing Kinesis stream as its source. To specify a Kinesis data stream as input, set the <code>DeliveryStreamType</code> parameter to <code>KinesisStreamAsSource</code>, and provide the Kinesis stream Amazon Resource Name (ARN) and role ARN in the <code>KinesisStreamSourceConfiguration</code> parameter.</p> <p>A delivery stream is configured with a single destination: Amazon S3, Amazon ES, Amazon Redshift, or Splunk. You must specify only one of the following destination configuration parameters: <code>ExtendedS3DestinationConfiguration</code>, <code>S3DestinationConfiguration</code>, <code>ElasticsearchDestinationConfiguration</code>, <code>RedshiftDestinationConfiguration</code>, or <code>SplunkDestinationConfiguration</code>.</p> <p>When you specify <code>S3DestinationConfiguration</code>, you can also provide the following optional values: BufferingHints, <code>EncryptionConfiguration</code>, and <code>CompressionFormat</code>. By default, if no <code>BufferingHints</code> value is provided, Kinesis Data Firehose buffers data up to 5 MB or for 5 minutes, whichever condition is satisfied first. <code>BufferingHints</code> is a hint, so there are some cases where the service cannot adhere to these conditions strictly. For example, record boundaries might be such that the size is a little over or under the configured buffering size. By default, no encryption is performed. We strongly recommend that you enable encryption to ensure secure data storage in Amazon S3.</p> <p>A few notes about Amazon Redshift as a destination:</p> <ul> <li> <p>An Amazon Redshift destination requires an S3 bucket as intermediate location. Kinesis Data Firehose first delivers data to Amazon S3 and then uses <code>COPY</code> syntax to load data into an Amazon Redshift table. This is specified in the <code>RedshiftDestinationConfiguration.S3Configuration</code> parameter.</p> </li> <li> <p>The compression formats <code>SNAPPY</code> or <code>ZIP</code> cannot be specified in <code>RedshiftDestinationConfiguration.S3Configuration</code> because the Amazon Redshift <code>COPY</code> operation that reads from the S3 bucket doesn't support these compression formats.</p> </li> <li> <p>We strongly recommend that you use the user name and password you provide exclusively with Kinesis Data Firehose, and that the permissions for the account are restricted for Amazon Redshift <code>INSERT</code> permissions.</p> </li> </ul> <p>Kinesis Data Firehose assumes the IAM role that is configured as part of the destination. The role should allow the Kinesis Data Firehose principal to assume the role, and the role should have permissions that allow the service to deliver the data. For more information, see <a href="https://docs.aws.amazon.com/firehose/latest/dev/controlling-access.html#using-iam-s3">Grant Kinesis Data Firehose Access to an Amazon S3 Destination</a> in the <i>Amazon Kinesis Data Firehose Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_590933 = newJObject()
  if body != nil:
    body_590933 = body
  result = call_590932.call(nil, nil, nil, nil, body_590933)

var createDeliveryStream* = Call_CreateDeliveryStream_590703(
    name: "createDeliveryStream", meth: HttpMethod.HttpPost,
    host: "firehose.amazonaws.com",
    route: "/#X-Amz-Target=Firehose_20150804.CreateDeliveryStream",
    validator: validate_CreateDeliveryStream_590704, base: "/",
    url: url_CreateDeliveryStream_590705, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDeliveryStream_590972 = ref object of OpenApiRestCall_590364
proc url_DeleteDeliveryStream_590974(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteDeliveryStream_590973(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes a delivery stream and its data.</p> <p>You can delete a delivery stream only if it is in <code>ACTIVE</code> or <code>DELETING</code> state, and not in the <code>CREATING</code> state. While the deletion request is in process, the delivery stream is in the <code>DELETING</code> state.</p> <p>To check the state of a delivery stream, use <a>DescribeDeliveryStream</a>.</p> <p>While the delivery stream is <code>DELETING</code> state, the service might continue to accept the records, but it doesn't make any guarantees with respect to delivering the data. Therefore, as a best practice, you should first stop any applications that are sending records before deleting a delivery stream.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_590975 = header.getOrDefault("X-Amz-Target")
  valid_590975 = validateParameter(valid_590975, JString, required = true, default = newJString(
      "Firehose_20150804.DeleteDeliveryStream"))
  if valid_590975 != nil:
    section.add "X-Amz-Target", valid_590975
  var valid_590976 = header.getOrDefault("X-Amz-Signature")
  valid_590976 = validateParameter(valid_590976, JString, required = false,
                                 default = nil)
  if valid_590976 != nil:
    section.add "X-Amz-Signature", valid_590976
  var valid_590977 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590977 = validateParameter(valid_590977, JString, required = false,
                                 default = nil)
  if valid_590977 != nil:
    section.add "X-Amz-Content-Sha256", valid_590977
  var valid_590978 = header.getOrDefault("X-Amz-Date")
  valid_590978 = validateParameter(valid_590978, JString, required = false,
                                 default = nil)
  if valid_590978 != nil:
    section.add "X-Amz-Date", valid_590978
  var valid_590979 = header.getOrDefault("X-Amz-Credential")
  valid_590979 = validateParameter(valid_590979, JString, required = false,
                                 default = nil)
  if valid_590979 != nil:
    section.add "X-Amz-Credential", valid_590979
  var valid_590980 = header.getOrDefault("X-Amz-Security-Token")
  valid_590980 = validateParameter(valid_590980, JString, required = false,
                                 default = nil)
  if valid_590980 != nil:
    section.add "X-Amz-Security-Token", valid_590980
  var valid_590981 = header.getOrDefault("X-Amz-Algorithm")
  valid_590981 = validateParameter(valid_590981, JString, required = false,
                                 default = nil)
  if valid_590981 != nil:
    section.add "X-Amz-Algorithm", valid_590981
  var valid_590982 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590982 = validateParameter(valid_590982, JString, required = false,
                                 default = nil)
  if valid_590982 != nil:
    section.add "X-Amz-SignedHeaders", valid_590982
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_590984: Call_DeleteDeliveryStream_590972; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a delivery stream and its data.</p> <p>You can delete a delivery stream only if it is in <code>ACTIVE</code> or <code>DELETING</code> state, and not in the <code>CREATING</code> state. While the deletion request is in process, the delivery stream is in the <code>DELETING</code> state.</p> <p>To check the state of a delivery stream, use <a>DescribeDeliveryStream</a>.</p> <p>While the delivery stream is <code>DELETING</code> state, the service might continue to accept the records, but it doesn't make any guarantees with respect to delivering the data. Therefore, as a best practice, you should first stop any applications that are sending records before deleting a delivery stream.</p>
  ## 
  let valid = call_590984.validator(path, query, header, formData, body)
  let scheme = call_590984.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590984.url(scheme.get, call_590984.host, call_590984.base,
                         call_590984.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590984, url, valid)

proc call*(call_590985: Call_DeleteDeliveryStream_590972; body: JsonNode): Recallable =
  ## deleteDeliveryStream
  ## <p>Deletes a delivery stream and its data.</p> <p>You can delete a delivery stream only if it is in <code>ACTIVE</code> or <code>DELETING</code> state, and not in the <code>CREATING</code> state. While the deletion request is in process, the delivery stream is in the <code>DELETING</code> state.</p> <p>To check the state of a delivery stream, use <a>DescribeDeliveryStream</a>.</p> <p>While the delivery stream is <code>DELETING</code> state, the service might continue to accept the records, but it doesn't make any guarantees with respect to delivering the data. Therefore, as a best practice, you should first stop any applications that are sending records before deleting a delivery stream.</p>
  ##   body: JObject (required)
  var body_590986 = newJObject()
  if body != nil:
    body_590986 = body
  result = call_590985.call(nil, nil, nil, nil, body_590986)

var deleteDeliveryStream* = Call_DeleteDeliveryStream_590972(
    name: "deleteDeliveryStream", meth: HttpMethod.HttpPost,
    host: "firehose.amazonaws.com",
    route: "/#X-Amz-Target=Firehose_20150804.DeleteDeliveryStream",
    validator: validate_DeleteDeliveryStream_590973, base: "/",
    url: url_DeleteDeliveryStream_590974, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDeliveryStream_590987 = ref object of OpenApiRestCall_590364
proc url_DescribeDeliveryStream_590989(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeDeliveryStream_590988(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the specified delivery stream and gets the status. For example, after your delivery stream is created, call <code>DescribeDeliveryStream</code> to see whether the delivery stream is <code>ACTIVE</code> and therefore ready for data to be sent to it.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_590990 = header.getOrDefault("X-Amz-Target")
  valid_590990 = validateParameter(valid_590990, JString, required = true, default = newJString(
      "Firehose_20150804.DescribeDeliveryStream"))
  if valid_590990 != nil:
    section.add "X-Amz-Target", valid_590990
  var valid_590991 = header.getOrDefault("X-Amz-Signature")
  valid_590991 = validateParameter(valid_590991, JString, required = false,
                                 default = nil)
  if valid_590991 != nil:
    section.add "X-Amz-Signature", valid_590991
  var valid_590992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590992 = validateParameter(valid_590992, JString, required = false,
                                 default = nil)
  if valid_590992 != nil:
    section.add "X-Amz-Content-Sha256", valid_590992
  var valid_590993 = header.getOrDefault("X-Amz-Date")
  valid_590993 = validateParameter(valid_590993, JString, required = false,
                                 default = nil)
  if valid_590993 != nil:
    section.add "X-Amz-Date", valid_590993
  var valid_590994 = header.getOrDefault("X-Amz-Credential")
  valid_590994 = validateParameter(valid_590994, JString, required = false,
                                 default = nil)
  if valid_590994 != nil:
    section.add "X-Amz-Credential", valid_590994
  var valid_590995 = header.getOrDefault("X-Amz-Security-Token")
  valid_590995 = validateParameter(valid_590995, JString, required = false,
                                 default = nil)
  if valid_590995 != nil:
    section.add "X-Amz-Security-Token", valid_590995
  var valid_590996 = header.getOrDefault("X-Amz-Algorithm")
  valid_590996 = validateParameter(valid_590996, JString, required = false,
                                 default = nil)
  if valid_590996 != nil:
    section.add "X-Amz-Algorithm", valid_590996
  var valid_590997 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590997 = validateParameter(valid_590997, JString, required = false,
                                 default = nil)
  if valid_590997 != nil:
    section.add "X-Amz-SignedHeaders", valid_590997
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_590999: Call_DescribeDeliveryStream_590987; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified delivery stream and gets the status. For example, after your delivery stream is created, call <code>DescribeDeliveryStream</code> to see whether the delivery stream is <code>ACTIVE</code> and therefore ready for data to be sent to it.
  ## 
  let valid = call_590999.validator(path, query, header, formData, body)
  let scheme = call_590999.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590999.url(scheme.get, call_590999.host, call_590999.base,
                         call_590999.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590999, url, valid)

proc call*(call_591000: Call_DescribeDeliveryStream_590987; body: JsonNode): Recallable =
  ## describeDeliveryStream
  ## Describes the specified delivery stream and gets the status. For example, after your delivery stream is created, call <code>DescribeDeliveryStream</code> to see whether the delivery stream is <code>ACTIVE</code> and therefore ready for data to be sent to it.
  ##   body: JObject (required)
  var body_591001 = newJObject()
  if body != nil:
    body_591001 = body
  result = call_591000.call(nil, nil, nil, nil, body_591001)

var describeDeliveryStream* = Call_DescribeDeliveryStream_590987(
    name: "describeDeliveryStream", meth: HttpMethod.HttpPost,
    host: "firehose.amazonaws.com",
    route: "/#X-Amz-Target=Firehose_20150804.DescribeDeliveryStream",
    validator: validate_DescribeDeliveryStream_590988, base: "/",
    url: url_DescribeDeliveryStream_590989, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeliveryStreams_591002 = ref object of OpenApiRestCall_590364
proc url_ListDeliveryStreams_591004(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListDeliveryStreams_591003(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Lists your delivery streams in alphabetical order of their names.</p> <p>The number of delivery streams might be too large to return using a single call to <code>ListDeliveryStreams</code>. You can limit the number of delivery streams returned, using the <code>Limit</code> parameter. To determine whether there are more delivery streams to list, check the value of <code>HasMoreDeliveryStreams</code> in the output. If there are more delivery streams to list, you can request them by calling this operation again and setting the <code>ExclusiveStartDeliveryStreamName</code> parameter to the name of the last delivery stream returned in the last call.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591005 = header.getOrDefault("X-Amz-Target")
  valid_591005 = validateParameter(valid_591005, JString, required = true, default = newJString(
      "Firehose_20150804.ListDeliveryStreams"))
  if valid_591005 != nil:
    section.add "X-Amz-Target", valid_591005
  var valid_591006 = header.getOrDefault("X-Amz-Signature")
  valid_591006 = validateParameter(valid_591006, JString, required = false,
                                 default = nil)
  if valid_591006 != nil:
    section.add "X-Amz-Signature", valid_591006
  var valid_591007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591007 = validateParameter(valid_591007, JString, required = false,
                                 default = nil)
  if valid_591007 != nil:
    section.add "X-Amz-Content-Sha256", valid_591007
  var valid_591008 = header.getOrDefault("X-Amz-Date")
  valid_591008 = validateParameter(valid_591008, JString, required = false,
                                 default = nil)
  if valid_591008 != nil:
    section.add "X-Amz-Date", valid_591008
  var valid_591009 = header.getOrDefault("X-Amz-Credential")
  valid_591009 = validateParameter(valid_591009, JString, required = false,
                                 default = nil)
  if valid_591009 != nil:
    section.add "X-Amz-Credential", valid_591009
  var valid_591010 = header.getOrDefault("X-Amz-Security-Token")
  valid_591010 = validateParameter(valid_591010, JString, required = false,
                                 default = nil)
  if valid_591010 != nil:
    section.add "X-Amz-Security-Token", valid_591010
  var valid_591011 = header.getOrDefault("X-Amz-Algorithm")
  valid_591011 = validateParameter(valid_591011, JString, required = false,
                                 default = nil)
  if valid_591011 != nil:
    section.add "X-Amz-Algorithm", valid_591011
  var valid_591012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591012 = validateParameter(valid_591012, JString, required = false,
                                 default = nil)
  if valid_591012 != nil:
    section.add "X-Amz-SignedHeaders", valid_591012
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591014: Call_ListDeliveryStreams_591002; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists your delivery streams in alphabetical order of their names.</p> <p>The number of delivery streams might be too large to return using a single call to <code>ListDeliveryStreams</code>. You can limit the number of delivery streams returned, using the <code>Limit</code> parameter. To determine whether there are more delivery streams to list, check the value of <code>HasMoreDeliveryStreams</code> in the output. If there are more delivery streams to list, you can request them by calling this operation again and setting the <code>ExclusiveStartDeliveryStreamName</code> parameter to the name of the last delivery stream returned in the last call.</p>
  ## 
  let valid = call_591014.validator(path, query, header, formData, body)
  let scheme = call_591014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591014.url(scheme.get, call_591014.host, call_591014.base,
                         call_591014.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591014, url, valid)

proc call*(call_591015: Call_ListDeliveryStreams_591002; body: JsonNode): Recallable =
  ## listDeliveryStreams
  ## <p>Lists your delivery streams in alphabetical order of their names.</p> <p>The number of delivery streams might be too large to return using a single call to <code>ListDeliveryStreams</code>. You can limit the number of delivery streams returned, using the <code>Limit</code> parameter. To determine whether there are more delivery streams to list, check the value of <code>HasMoreDeliveryStreams</code> in the output. If there are more delivery streams to list, you can request them by calling this operation again and setting the <code>ExclusiveStartDeliveryStreamName</code> parameter to the name of the last delivery stream returned in the last call.</p>
  ##   body: JObject (required)
  var body_591016 = newJObject()
  if body != nil:
    body_591016 = body
  result = call_591015.call(nil, nil, nil, nil, body_591016)

var listDeliveryStreams* = Call_ListDeliveryStreams_591002(
    name: "listDeliveryStreams", meth: HttpMethod.HttpPost,
    host: "firehose.amazonaws.com",
    route: "/#X-Amz-Target=Firehose_20150804.ListDeliveryStreams",
    validator: validate_ListDeliveryStreams_591003, base: "/",
    url: url_ListDeliveryStreams_591004, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForDeliveryStream_591017 = ref object of OpenApiRestCall_590364
proc url_ListTagsForDeliveryStream_591019(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTagsForDeliveryStream_591018(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the tags for the specified delivery stream. This operation has a limit of five transactions per second per account. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591020 = header.getOrDefault("X-Amz-Target")
  valid_591020 = validateParameter(valid_591020, JString, required = true, default = newJString(
      "Firehose_20150804.ListTagsForDeliveryStream"))
  if valid_591020 != nil:
    section.add "X-Amz-Target", valid_591020
  var valid_591021 = header.getOrDefault("X-Amz-Signature")
  valid_591021 = validateParameter(valid_591021, JString, required = false,
                                 default = nil)
  if valid_591021 != nil:
    section.add "X-Amz-Signature", valid_591021
  var valid_591022 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591022 = validateParameter(valid_591022, JString, required = false,
                                 default = nil)
  if valid_591022 != nil:
    section.add "X-Amz-Content-Sha256", valid_591022
  var valid_591023 = header.getOrDefault("X-Amz-Date")
  valid_591023 = validateParameter(valid_591023, JString, required = false,
                                 default = nil)
  if valid_591023 != nil:
    section.add "X-Amz-Date", valid_591023
  var valid_591024 = header.getOrDefault("X-Amz-Credential")
  valid_591024 = validateParameter(valid_591024, JString, required = false,
                                 default = nil)
  if valid_591024 != nil:
    section.add "X-Amz-Credential", valid_591024
  var valid_591025 = header.getOrDefault("X-Amz-Security-Token")
  valid_591025 = validateParameter(valid_591025, JString, required = false,
                                 default = nil)
  if valid_591025 != nil:
    section.add "X-Amz-Security-Token", valid_591025
  var valid_591026 = header.getOrDefault("X-Amz-Algorithm")
  valid_591026 = validateParameter(valid_591026, JString, required = false,
                                 default = nil)
  if valid_591026 != nil:
    section.add "X-Amz-Algorithm", valid_591026
  var valid_591027 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591027 = validateParameter(valid_591027, JString, required = false,
                                 default = nil)
  if valid_591027 != nil:
    section.add "X-Amz-SignedHeaders", valid_591027
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591029: Call_ListTagsForDeliveryStream_591017; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags for the specified delivery stream. This operation has a limit of five transactions per second per account. 
  ## 
  let valid = call_591029.validator(path, query, header, formData, body)
  let scheme = call_591029.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591029.url(scheme.get, call_591029.host, call_591029.base,
                         call_591029.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591029, url, valid)

proc call*(call_591030: Call_ListTagsForDeliveryStream_591017; body: JsonNode): Recallable =
  ## listTagsForDeliveryStream
  ## Lists the tags for the specified delivery stream. This operation has a limit of five transactions per second per account. 
  ##   body: JObject (required)
  var body_591031 = newJObject()
  if body != nil:
    body_591031 = body
  result = call_591030.call(nil, nil, nil, nil, body_591031)

var listTagsForDeliveryStream* = Call_ListTagsForDeliveryStream_591017(
    name: "listTagsForDeliveryStream", meth: HttpMethod.HttpPost,
    host: "firehose.amazonaws.com",
    route: "/#X-Amz-Target=Firehose_20150804.ListTagsForDeliveryStream",
    validator: validate_ListTagsForDeliveryStream_591018, base: "/",
    url: url_ListTagsForDeliveryStream_591019,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutRecord_591032 = ref object of OpenApiRestCall_590364
proc url_PutRecord_591034(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutRecord_591033(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Writes a single data record into an Amazon Kinesis Data Firehose delivery stream. To write multiple data records into a delivery stream, use <a>PutRecordBatch</a>. Applications using these operations are referred to as producers.</p> <p>By default, each delivery stream can take in up to 2,000 transactions per second, 5,000 records per second, or 5 MB per second. If you use <a>PutRecord</a> and <a>PutRecordBatch</a>, the limits are an aggregate across these two operations for each delivery stream. For more information about limits and how to request an increase, see <a href="https://docs.aws.amazon.com/firehose/latest/dev/limits.html">Amazon Kinesis Data Firehose Limits</a>. </p> <p>You must specify the name of the delivery stream and the data record when using <a>PutRecord</a>. The data record consists of a data blob that can be up to 1,000 KB in size, and any kind of data. For example, it can be a segment from a log file, geographic location data, website clickstream data, and so on.</p> <p>Kinesis Data Firehose buffers records before delivering them to the destination. To disambiguate the data blobs at the destination, a common solution is to use delimiters in the data, such as a newline (<code>\n</code>) or some other character unique within the data. This allows the consumer application to parse individual data items when reading the data from the destination.</p> <p>The <code>PutRecord</code> operation returns a <code>RecordId</code>, which is a unique string assigned to each record. Producer applications can use this ID for purposes such as auditability and investigation.</p> <p>If the <code>PutRecord</code> operation throws a <code>ServiceUnavailableException</code>, back off and retry. If the exception persists, it is possible that the throughput limits have been exceeded for the delivery stream. </p> <p>Data records sent to Kinesis Data Firehose are stored for 24 hours from the time they are added to a delivery stream as it tries to send the records to the destination. If the destination is unreachable for more than 24 hours, the data is no longer available.</p> <important> <p>Don't concatenate two or more base64 strings to form the data fields of your records. Instead, concatenate the raw data, then perform base64 encoding.</p> </important>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591035 = header.getOrDefault("X-Amz-Target")
  valid_591035 = validateParameter(valid_591035, JString, required = true, default = newJString(
      "Firehose_20150804.PutRecord"))
  if valid_591035 != nil:
    section.add "X-Amz-Target", valid_591035
  var valid_591036 = header.getOrDefault("X-Amz-Signature")
  valid_591036 = validateParameter(valid_591036, JString, required = false,
                                 default = nil)
  if valid_591036 != nil:
    section.add "X-Amz-Signature", valid_591036
  var valid_591037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591037 = validateParameter(valid_591037, JString, required = false,
                                 default = nil)
  if valid_591037 != nil:
    section.add "X-Amz-Content-Sha256", valid_591037
  var valid_591038 = header.getOrDefault("X-Amz-Date")
  valid_591038 = validateParameter(valid_591038, JString, required = false,
                                 default = nil)
  if valid_591038 != nil:
    section.add "X-Amz-Date", valid_591038
  var valid_591039 = header.getOrDefault("X-Amz-Credential")
  valid_591039 = validateParameter(valid_591039, JString, required = false,
                                 default = nil)
  if valid_591039 != nil:
    section.add "X-Amz-Credential", valid_591039
  var valid_591040 = header.getOrDefault("X-Amz-Security-Token")
  valid_591040 = validateParameter(valid_591040, JString, required = false,
                                 default = nil)
  if valid_591040 != nil:
    section.add "X-Amz-Security-Token", valid_591040
  var valid_591041 = header.getOrDefault("X-Amz-Algorithm")
  valid_591041 = validateParameter(valid_591041, JString, required = false,
                                 default = nil)
  if valid_591041 != nil:
    section.add "X-Amz-Algorithm", valid_591041
  var valid_591042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591042 = validateParameter(valid_591042, JString, required = false,
                                 default = nil)
  if valid_591042 != nil:
    section.add "X-Amz-SignedHeaders", valid_591042
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591044: Call_PutRecord_591032; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Writes a single data record into an Amazon Kinesis Data Firehose delivery stream. To write multiple data records into a delivery stream, use <a>PutRecordBatch</a>. Applications using these operations are referred to as producers.</p> <p>By default, each delivery stream can take in up to 2,000 transactions per second, 5,000 records per second, or 5 MB per second. If you use <a>PutRecord</a> and <a>PutRecordBatch</a>, the limits are an aggregate across these two operations for each delivery stream. For more information about limits and how to request an increase, see <a href="https://docs.aws.amazon.com/firehose/latest/dev/limits.html">Amazon Kinesis Data Firehose Limits</a>. </p> <p>You must specify the name of the delivery stream and the data record when using <a>PutRecord</a>. The data record consists of a data blob that can be up to 1,000 KB in size, and any kind of data. For example, it can be a segment from a log file, geographic location data, website clickstream data, and so on.</p> <p>Kinesis Data Firehose buffers records before delivering them to the destination. To disambiguate the data blobs at the destination, a common solution is to use delimiters in the data, such as a newline (<code>\n</code>) or some other character unique within the data. This allows the consumer application to parse individual data items when reading the data from the destination.</p> <p>The <code>PutRecord</code> operation returns a <code>RecordId</code>, which is a unique string assigned to each record. Producer applications can use this ID for purposes such as auditability and investigation.</p> <p>If the <code>PutRecord</code> operation throws a <code>ServiceUnavailableException</code>, back off and retry. If the exception persists, it is possible that the throughput limits have been exceeded for the delivery stream. </p> <p>Data records sent to Kinesis Data Firehose are stored for 24 hours from the time they are added to a delivery stream as it tries to send the records to the destination. If the destination is unreachable for more than 24 hours, the data is no longer available.</p> <important> <p>Don't concatenate two or more base64 strings to form the data fields of your records. Instead, concatenate the raw data, then perform base64 encoding.</p> </important>
  ## 
  let valid = call_591044.validator(path, query, header, formData, body)
  let scheme = call_591044.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591044.url(scheme.get, call_591044.host, call_591044.base,
                         call_591044.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591044, url, valid)

proc call*(call_591045: Call_PutRecord_591032; body: JsonNode): Recallable =
  ## putRecord
  ## <p>Writes a single data record into an Amazon Kinesis Data Firehose delivery stream. To write multiple data records into a delivery stream, use <a>PutRecordBatch</a>. Applications using these operations are referred to as producers.</p> <p>By default, each delivery stream can take in up to 2,000 transactions per second, 5,000 records per second, or 5 MB per second. If you use <a>PutRecord</a> and <a>PutRecordBatch</a>, the limits are an aggregate across these two operations for each delivery stream. For more information about limits and how to request an increase, see <a href="https://docs.aws.amazon.com/firehose/latest/dev/limits.html">Amazon Kinesis Data Firehose Limits</a>. </p> <p>You must specify the name of the delivery stream and the data record when using <a>PutRecord</a>. The data record consists of a data blob that can be up to 1,000 KB in size, and any kind of data. For example, it can be a segment from a log file, geographic location data, website clickstream data, and so on.</p> <p>Kinesis Data Firehose buffers records before delivering them to the destination. To disambiguate the data blobs at the destination, a common solution is to use delimiters in the data, such as a newline (<code>\n</code>) or some other character unique within the data. This allows the consumer application to parse individual data items when reading the data from the destination.</p> <p>The <code>PutRecord</code> operation returns a <code>RecordId</code>, which is a unique string assigned to each record. Producer applications can use this ID for purposes such as auditability and investigation.</p> <p>If the <code>PutRecord</code> operation throws a <code>ServiceUnavailableException</code>, back off and retry. If the exception persists, it is possible that the throughput limits have been exceeded for the delivery stream. </p> <p>Data records sent to Kinesis Data Firehose are stored for 24 hours from the time they are added to a delivery stream as it tries to send the records to the destination. If the destination is unreachable for more than 24 hours, the data is no longer available.</p> <important> <p>Don't concatenate two or more base64 strings to form the data fields of your records. Instead, concatenate the raw data, then perform base64 encoding.</p> </important>
  ##   body: JObject (required)
  var body_591046 = newJObject()
  if body != nil:
    body_591046 = body
  result = call_591045.call(nil, nil, nil, nil, body_591046)

var putRecord* = Call_PutRecord_591032(name: "putRecord", meth: HttpMethod.HttpPost,
                                    host: "firehose.amazonaws.com", route: "/#X-Amz-Target=Firehose_20150804.PutRecord",
                                    validator: validate_PutRecord_591033,
                                    base: "/", url: url_PutRecord_591034,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutRecordBatch_591047 = ref object of OpenApiRestCall_590364
proc url_PutRecordBatch_591049(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutRecordBatch_591048(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Writes multiple data records into a delivery stream in a single call, which can achieve higher throughput per producer than when writing single records. To write single data records into a delivery stream, use <a>PutRecord</a>. Applications using these operations are referred to as producers.</p> <p>By default, each delivery stream can take in up to 2,000 transactions per second, 5,000 records per second, or 5 MB per second. If you use <a>PutRecord</a> and <a>PutRecordBatch</a>, the limits are an aggregate across these two operations for each delivery stream. For more information about limits, see <a href="https://docs.aws.amazon.com/firehose/latest/dev/limits.html">Amazon Kinesis Data Firehose Limits</a>.</p> <p>Each <a>PutRecordBatch</a> request supports up to 500 records. Each record in the request can be as large as 1,000 KB (before 64-bit encoding), up to a limit of 4 MB for the entire request. These limits cannot be changed.</p> <p>You must specify the name of the delivery stream and the data record when using <a>PutRecord</a>. The data record consists of a data blob that can be up to 1,000 KB in size, and any kind of data. For example, it could be a segment from a log file, geographic location data, website clickstream data, and so on.</p> <p>Kinesis Data Firehose buffers records before delivering them to the destination. To disambiguate the data blobs at the destination, a common solution is to use delimiters in the data, such as a newline (<code>\n</code>) or some other character unique within the data. This allows the consumer application to parse individual data items when reading the data from the destination.</p> <p>The <a>PutRecordBatch</a> response includes a count of failed records, <code>FailedPutCount</code>, and an array of responses, <code>RequestResponses</code>. Even if the <a>PutRecordBatch</a> call succeeds, the value of <code>FailedPutCount</code> may be greater than 0, indicating that there are records for which the operation didn't succeed. Each entry in the <code>RequestResponses</code> array provides additional information about the processed record. It directly correlates with a record in the request array using the same ordering, from the top to the bottom. The response array always includes the same number of records as the request array. <code>RequestResponses</code> includes both successfully and unsuccessfully processed records. Kinesis Data Firehose tries to process all records in each <a>PutRecordBatch</a> request. A single record failure does not stop the processing of subsequent records. </p> <p>A successfully processed record includes a <code>RecordId</code> value, which is unique for the record. An unsuccessfully processed record includes <code>ErrorCode</code> and <code>ErrorMessage</code> values. <code>ErrorCode</code> reflects the type of error, and is one of the following values: <code>ServiceUnavailableException</code> or <code>InternalFailure</code>. <code>ErrorMessage</code> provides more detailed information about the error.</p> <p>If there is an internal server error or a timeout, the write might have completed or it might have failed. If <code>FailedPutCount</code> is greater than 0, retry the request, resending only those records that might have failed processing. This minimizes the possible duplicate records and also reduces the total bytes sent (and corresponding charges). We recommend that you handle any duplicates at the destination.</p> <p>If <a>PutRecordBatch</a> throws <code>ServiceUnavailableException</code>, back off and retry. If the exception persists, it is possible that the throughput limits have been exceeded for the delivery stream.</p> <p>Data records sent to Kinesis Data Firehose are stored for 24 hours from the time they are added to a delivery stream as it attempts to send the records to the destination. If the destination is unreachable for more than 24 hours, the data is no longer available.</p> <important> <p>Don't concatenate two or more base64 strings to form the data fields of your records. Instead, concatenate the raw data, then perform base64 encoding.</p> </important>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591050 = header.getOrDefault("X-Amz-Target")
  valid_591050 = validateParameter(valid_591050, JString, required = true, default = newJString(
      "Firehose_20150804.PutRecordBatch"))
  if valid_591050 != nil:
    section.add "X-Amz-Target", valid_591050
  var valid_591051 = header.getOrDefault("X-Amz-Signature")
  valid_591051 = validateParameter(valid_591051, JString, required = false,
                                 default = nil)
  if valid_591051 != nil:
    section.add "X-Amz-Signature", valid_591051
  var valid_591052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591052 = validateParameter(valid_591052, JString, required = false,
                                 default = nil)
  if valid_591052 != nil:
    section.add "X-Amz-Content-Sha256", valid_591052
  var valid_591053 = header.getOrDefault("X-Amz-Date")
  valid_591053 = validateParameter(valid_591053, JString, required = false,
                                 default = nil)
  if valid_591053 != nil:
    section.add "X-Amz-Date", valid_591053
  var valid_591054 = header.getOrDefault("X-Amz-Credential")
  valid_591054 = validateParameter(valid_591054, JString, required = false,
                                 default = nil)
  if valid_591054 != nil:
    section.add "X-Amz-Credential", valid_591054
  var valid_591055 = header.getOrDefault("X-Amz-Security-Token")
  valid_591055 = validateParameter(valid_591055, JString, required = false,
                                 default = nil)
  if valid_591055 != nil:
    section.add "X-Amz-Security-Token", valid_591055
  var valid_591056 = header.getOrDefault("X-Amz-Algorithm")
  valid_591056 = validateParameter(valid_591056, JString, required = false,
                                 default = nil)
  if valid_591056 != nil:
    section.add "X-Amz-Algorithm", valid_591056
  var valid_591057 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591057 = validateParameter(valid_591057, JString, required = false,
                                 default = nil)
  if valid_591057 != nil:
    section.add "X-Amz-SignedHeaders", valid_591057
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591059: Call_PutRecordBatch_591047; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Writes multiple data records into a delivery stream in a single call, which can achieve higher throughput per producer than when writing single records. To write single data records into a delivery stream, use <a>PutRecord</a>. Applications using these operations are referred to as producers.</p> <p>By default, each delivery stream can take in up to 2,000 transactions per second, 5,000 records per second, or 5 MB per second. If you use <a>PutRecord</a> and <a>PutRecordBatch</a>, the limits are an aggregate across these two operations for each delivery stream. For more information about limits, see <a href="https://docs.aws.amazon.com/firehose/latest/dev/limits.html">Amazon Kinesis Data Firehose Limits</a>.</p> <p>Each <a>PutRecordBatch</a> request supports up to 500 records. Each record in the request can be as large as 1,000 KB (before 64-bit encoding), up to a limit of 4 MB for the entire request. These limits cannot be changed.</p> <p>You must specify the name of the delivery stream and the data record when using <a>PutRecord</a>. The data record consists of a data blob that can be up to 1,000 KB in size, and any kind of data. For example, it could be a segment from a log file, geographic location data, website clickstream data, and so on.</p> <p>Kinesis Data Firehose buffers records before delivering them to the destination. To disambiguate the data blobs at the destination, a common solution is to use delimiters in the data, such as a newline (<code>\n</code>) or some other character unique within the data. This allows the consumer application to parse individual data items when reading the data from the destination.</p> <p>The <a>PutRecordBatch</a> response includes a count of failed records, <code>FailedPutCount</code>, and an array of responses, <code>RequestResponses</code>. Even if the <a>PutRecordBatch</a> call succeeds, the value of <code>FailedPutCount</code> may be greater than 0, indicating that there are records for which the operation didn't succeed. Each entry in the <code>RequestResponses</code> array provides additional information about the processed record. It directly correlates with a record in the request array using the same ordering, from the top to the bottom. The response array always includes the same number of records as the request array. <code>RequestResponses</code> includes both successfully and unsuccessfully processed records. Kinesis Data Firehose tries to process all records in each <a>PutRecordBatch</a> request. A single record failure does not stop the processing of subsequent records. </p> <p>A successfully processed record includes a <code>RecordId</code> value, which is unique for the record. An unsuccessfully processed record includes <code>ErrorCode</code> and <code>ErrorMessage</code> values. <code>ErrorCode</code> reflects the type of error, and is one of the following values: <code>ServiceUnavailableException</code> or <code>InternalFailure</code>. <code>ErrorMessage</code> provides more detailed information about the error.</p> <p>If there is an internal server error or a timeout, the write might have completed or it might have failed. If <code>FailedPutCount</code> is greater than 0, retry the request, resending only those records that might have failed processing. This minimizes the possible duplicate records and also reduces the total bytes sent (and corresponding charges). We recommend that you handle any duplicates at the destination.</p> <p>If <a>PutRecordBatch</a> throws <code>ServiceUnavailableException</code>, back off and retry. If the exception persists, it is possible that the throughput limits have been exceeded for the delivery stream.</p> <p>Data records sent to Kinesis Data Firehose are stored for 24 hours from the time they are added to a delivery stream as it attempts to send the records to the destination. If the destination is unreachable for more than 24 hours, the data is no longer available.</p> <important> <p>Don't concatenate two or more base64 strings to form the data fields of your records. Instead, concatenate the raw data, then perform base64 encoding.</p> </important>
  ## 
  let valid = call_591059.validator(path, query, header, formData, body)
  let scheme = call_591059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591059.url(scheme.get, call_591059.host, call_591059.base,
                         call_591059.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591059, url, valid)

proc call*(call_591060: Call_PutRecordBatch_591047; body: JsonNode): Recallable =
  ## putRecordBatch
  ## <p>Writes multiple data records into a delivery stream in a single call, which can achieve higher throughput per producer than when writing single records. To write single data records into a delivery stream, use <a>PutRecord</a>. Applications using these operations are referred to as producers.</p> <p>By default, each delivery stream can take in up to 2,000 transactions per second, 5,000 records per second, or 5 MB per second. If you use <a>PutRecord</a> and <a>PutRecordBatch</a>, the limits are an aggregate across these two operations for each delivery stream. For more information about limits, see <a href="https://docs.aws.amazon.com/firehose/latest/dev/limits.html">Amazon Kinesis Data Firehose Limits</a>.</p> <p>Each <a>PutRecordBatch</a> request supports up to 500 records. Each record in the request can be as large as 1,000 KB (before 64-bit encoding), up to a limit of 4 MB for the entire request. These limits cannot be changed.</p> <p>You must specify the name of the delivery stream and the data record when using <a>PutRecord</a>. The data record consists of a data blob that can be up to 1,000 KB in size, and any kind of data. For example, it could be a segment from a log file, geographic location data, website clickstream data, and so on.</p> <p>Kinesis Data Firehose buffers records before delivering them to the destination. To disambiguate the data blobs at the destination, a common solution is to use delimiters in the data, such as a newline (<code>\n</code>) or some other character unique within the data. This allows the consumer application to parse individual data items when reading the data from the destination.</p> <p>The <a>PutRecordBatch</a> response includes a count of failed records, <code>FailedPutCount</code>, and an array of responses, <code>RequestResponses</code>. Even if the <a>PutRecordBatch</a> call succeeds, the value of <code>FailedPutCount</code> may be greater than 0, indicating that there are records for which the operation didn't succeed. Each entry in the <code>RequestResponses</code> array provides additional information about the processed record. It directly correlates with a record in the request array using the same ordering, from the top to the bottom. The response array always includes the same number of records as the request array. <code>RequestResponses</code> includes both successfully and unsuccessfully processed records. Kinesis Data Firehose tries to process all records in each <a>PutRecordBatch</a> request. A single record failure does not stop the processing of subsequent records. </p> <p>A successfully processed record includes a <code>RecordId</code> value, which is unique for the record. An unsuccessfully processed record includes <code>ErrorCode</code> and <code>ErrorMessage</code> values. <code>ErrorCode</code> reflects the type of error, and is one of the following values: <code>ServiceUnavailableException</code> or <code>InternalFailure</code>. <code>ErrorMessage</code> provides more detailed information about the error.</p> <p>If there is an internal server error or a timeout, the write might have completed or it might have failed. If <code>FailedPutCount</code> is greater than 0, retry the request, resending only those records that might have failed processing. This minimizes the possible duplicate records and also reduces the total bytes sent (and corresponding charges). We recommend that you handle any duplicates at the destination.</p> <p>If <a>PutRecordBatch</a> throws <code>ServiceUnavailableException</code>, back off and retry. If the exception persists, it is possible that the throughput limits have been exceeded for the delivery stream.</p> <p>Data records sent to Kinesis Data Firehose are stored for 24 hours from the time they are added to a delivery stream as it attempts to send the records to the destination. If the destination is unreachable for more than 24 hours, the data is no longer available.</p> <important> <p>Don't concatenate two or more base64 strings to form the data fields of your records. Instead, concatenate the raw data, then perform base64 encoding.</p> </important>
  ##   body: JObject (required)
  var body_591061 = newJObject()
  if body != nil:
    body_591061 = body
  result = call_591060.call(nil, nil, nil, nil, body_591061)

var putRecordBatch* = Call_PutRecordBatch_591047(name: "putRecordBatch",
    meth: HttpMethod.HttpPost, host: "firehose.amazonaws.com",
    route: "/#X-Amz-Target=Firehose_20150804.PutRecordBatch",
    validator: validate_PutRecordBatch_591048, base: "/", url: url_PutRecordBatch_591049,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartDeliveryStreamEncryption_591062 = ref object of OpenApiRestCall_590364
proc url_StartDeliveryStreamEncryption_591064(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartDeliveryStreamEncryption_591063(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Enables server-side encryption (SSE) for the delivery stream. </p> <p>This operation is asynchronous. It returns immediately. When you invoke it, Kinesis Data Firehose first sets the status of the stream to <code>ENABLING</code>, and then to <code>ENABLED</code>. You can continue to read and write data to your stream while its status is <code>ENABLING</code>, but the data is not encrypted. It can take up to 5 seconds after the encryption status changes to <code>ENABLED</code> before all records written to the delivery stream are encrypted. To find out whether a record or a batch of records was encrypted, check the response elements <a>PutRecordOutput$Encrypted</a> and <a>PutRecordBatchOutput$Encrypted</a>, respectively.</p> <p>To check the encryption state of a delivery stream, use <a>DescribeDeliveryStream</a>.</p> <p>You can only enable SSE for a delivery stream that uses <code>DirectPut</code> as its source. </p> <p>The <code>StartDeliveryStreamEncryption</code> and <code>StopDeliveryStreamEncryption</code> operations have a combined limit of 25 calls per delivery stream per 24 hours. For example, you reach the limit if you call <code>StartDeliveryStreamEncryption</code> 13 times and <code>StopDeliveryStreamEncryption</code> 12 times for the same delivery stream in a 24-hour period.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591065 = header.getOrDefault("X-Amz-Target")
  valid_591065 = validateParameter(valid_591065, JString, required = true, default = newJString(
      "Firehose_20150804.StartDeliveryStreamEncryption"))
  if valid_591065 != nil:
    section.add "X-Amz-Target", valid_591065
  var valid_591066 = header.getOrDefault("X-Amz-Signature")
  valid_591066 = validateParameter(valid_591066, JString, required = false,
                                 default = nil)
  if valid_591066 != nil:
    section.add "X-Amz-Signature", valid_591066
  var valid_591067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591067 = validateParameter(valid_591067, JString, required = false,
                                 default = nil)
  if valid_591067 != nil:
    section.add "X-Amz-Content-Sha256", valid_591067
  var valid_591068 = header.getOrDefault("X-Amz-Date")
  valid_591068 = validateParameter(valid_591068, JString, required = false,
                                 default = nil)
  if valid_591068 != nil:
    section.add "X-Amz-Date", valid_591068
  var valid_591069 = header.getOrDefault("X-Amz-Credential")
  valid_591069 = validateParameter(valid_591069, JString, required = false,
                                 default = nil)
  if valid_591069 != nil:
    section.add "X-Amz-Credential", valid_591069
  var valid_591070 = header.getOrDefault("X-Amz-Security-Token")
  valid_591070 = validateParameter(valid_591070, JString, required = false,
                                 default = nil)
  if valid_591070 != nil:
    section.add "X-Amz-Security-Token", valid_591070
  var valid_591071 = header.getOrDefault("X-Amz-Algorithm")
  valid_591071 = validateParameter(valid_591071, JString, required = false,
                                 default = nil)
  if valid_591071 != nil:
    section.add "X-Amz-Algorithm", valid_591071
  var valid_591072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591072 = validateParameter(valid_591072, JString, required = false,
                                 default = nil)
  if valid_591072 != nil:
    section.add "X-Amz-SignedHeaders", valid_591072
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591074: Call_StartDeliveryStreamEncryption_591062; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables server-side encryption (SSE) for the delivery stream. </p> <p>This operation is asynchronous. It returns immediately. When you invoke it, Kinesis Data Firehose first sets the status of the stream to <code>ENABLING</code>, and then to <code>ENABLED</code>. You can continue to read and write data to your stream while its status is <code>ENABLING</code>, but the data is not encrypted. It can take up to 5 seconds after the encryption status changes to <code>ENABLED</code> before all records written to the delivery stream are encrypted. To find out whether a record or a batch of records was encrypted, check the response elements <a>PutRecordOutput$Encrypted</a> and <a>PutRecordBatchOutput$Encrypted</a>, respectively.</p> <p>To check the encryption state of a delivery stream, use <a>DescribeDeliveryStream</a>.</p> <p>You can only enable SSE for a delivery stream that uses <code>DirectPut</code> as its source. </p> <p>The <code>StartDeliveryStreamEncryption</code> and <code>StopDeliveryStreamEncryption</code> operations have a combined limit of 25 calls per delivery stream per 24 hours. For example, you reach the limit if you call <code>StartDeliveryStreamEncryption</code> 13 times and <code>StopDeliveryStreamEncryption</code> 12 times for the same delivery stream in a 24-hour period.</p>
  ## 
  let valid = call_591074.validator(path, query, header, formData, body)
  let scheme = call_591074.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591074.url(scheme.get, call_591074.host, call_591074.base,
                         call_591074.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591074, url, valid)

proc call*(call_591075: Call_StartDeliveryStreamEncryption_591062; body: JsonNode): Recallable =
  ## startDeliveryStreamEncryption
  ## <p>Enables server-side encryption (SSE) for the delivery stream. </p> <p>This operation is asynchronous. It returns immediately. When you invoke it, Kinesis Data Firehose first sets the status of the stream to <code>ENABLING</code>, and then to <code>ENABLED</code>. You can continue to read and write data to your stream while its status is <code>ENABLING</code>, but the data is not encrypted. It can take up to 5 seconds after the encryption status changes to <code>ENABLED</code> before all records written to the delivery stream are encrypted. To find out whether a record or a batch of records was encrypted, check the response elements <a>PutRecordOutput$Encrypted</a> and <a>PutRecordBatchOutput$Encrypted</a>, respectively.</p> <p>To check the encryption state of a delivery stream, use <a>DescribeDeliveryStream</a>.</p> <p>You can only enable SSE for a delivery stream that uses <code>DirectPut</code> as its source. </p> <p>The <code>StartDeliveryStreamEncryption</code> and <code>StopDeliveryStreamEncryption</code> operations have a combined limit of 25 calls per delivery stream per 24 hours. For example, you reach the limit if you call <code>StartDeliveryStreamEncryption</code> 13 times and <code>StopDeliveryStreamEncryption</code> 12 times for the same delivery stream in a 24-hour period.</p>
  ##   body: JObject (required)
  var body_591076 = newJObject()
  if body != nil:
    body_591076 = body
  result = call_591075.call(nil, nil, nil, nil, body_591076)

var startDeliveryStreamEncryption* = Call_StartDeliveryStreamEncryption_591062(
    name: "startDeliveryStreamEncryption", meth: HttpMethod.HttpPost,
    host: "firehose.amazonaws.com",
    route: "/#X-Amz-Target=Firehose_20150804.StartDeliveryStreamEncryption",
    validator: validate_StartDeliveryStreamEncryption_591063, base: "/",
    url: url_StartDeliveryStreamEncryption_591064,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopDeliveryStreamEncryption_591077 = ref object of OpenApiRestCall_590364
proc url_StopDeliveryStreamEncryption_591079(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopDeliveryStreamEncryption_591078(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Disables server-side encryption (SSE) for the delivery stream. </p> <p>This operation is asynchronous. It returns immediately. When you invoke it, Kinesis Data Firehose first sets the status of the stream to <code>DISABLING</code>, and then to <code>DISABLED</code>. You can continue to read and write data to your stream while its status is <code>DISABLING</code>. It can take up to 5 seconds after the encryption status changes to <code>DISABLED</code> before all records written to the delivery stream are no longer subject to encryption. To find out whether a record or a batch of records was encrypted, check the response elements <a>PutRecordOutput$Encrypted</a> and <a>PutRecordBatchOutput$Encrypted</a>, respectively.</p> <p>To check the encryption state of a delivery stream, use <a>DescribeDeliveryStream</a>. </p> <p>The <code>StartDeliveryStreamEncryption</code> and <code>StopDeliveryStreamEncryption</code> operations have a combined limit of 25 calls per delivery stream per 24 hours. For example, you reach the limit if you call <code>StartDeliveryStreamEncryption</code> 13 times and <code>StopDeliveryStreamEncryption</code> 12 times for the same delivery stream in a 24-hour period.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591080 = header.getOrDefault("X-Amz-Target")
  valid_591080 = validateParameter(valid_591080, JString, required = true, default = newJString(
      "Firehose_20150804.StopDeliveryStreamEncryption"))
  if valid_591080 != nil:
    section.add "X-Amz-Target", valid_591080
  var valid_591081 = header.getOrDefault("X-Amz-Signature")
  valid_591081 = validateParameter(valid_591081, JString, required = false,
                                 default = nil)
  if valid_591081 != nil:
    section.add "X-Amz-Signature", valid_591081
  var valid_591082 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591082 = validateParameter(valid_591082, JString, required = false,
                                 default = nil)
  if valid_591082 != nil:
    section.add "X-Amz-Content-Sha256", valid_591082
  var valid_591083 = header.getOrDefault("X-Amz-Date")
  valid_591083 = validateParameter(valid_591083, JString, required = false,
                                 default = nil)
  if valid_591083 != nil:
    section.add "X-Amz-Date", valid_591083
  var valid_591084 = header.getOrDefault("X-Amz-Credential")
  valid_591084 = validateParameter(valid_591084, JString, required = false,
                                 default = nil)
  if valid_591084 != nil:
    section.add "X-Amz-Credential", valid_591084
  var valid_591085 = header.getOrDefault("X-Amz-Security-Token")
  valid_591085 = validateParameter(valid_591085, JString, required = false,
                                 default = nil)
  if valid_591085 != nil:
    section.add "X-Amz-Security-Token", valid_591085
  var valid_591086 = header.getOrDefault("X-Amz-Algorithm")
  valid_591086 = validateParameter(valid_591086, JString, required = false,
                                 default = nil)
  if valid_591086 != nil:
    section.add "X-Amz-Algorithm", valid_591086
  var valid_591087 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591087 = validateParameter(valid_591087, JString, required = false,
                                 default = nil)
  if valid_591087 != nil:
    section.add "X-Amz-SignedHeaders", valid_591087
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591089: Call_StopDeliveryStreamEncryption_591077; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disables server-side encryption (SSE) for the delivery stream. </p> <p>This operation is asynchronous. It returns immediately. When you invoke it, Kinesis Data Firehose first sets the status of the stream to <code>DISABLING</code>, and then to <code>DISABLED</code>. You can continue to read and write data to your stream while its status is <code>DISABLING</code>. It can take up to 5 seconds after the encryption status changes to <code>DISABLED</code> before all records written to the delivery stream are no longer subject to encryption. To find out whether a record or a batch of records was encrypted, check the response elements <a>PutRecordOutput$Encrypted</a> and <a>PutRecordBatchOutput$Encrypted</a>, respectively.</p> <p>To check the encryption state of a delivery stream, use <a>DescribeDeliveryStream</a>. </p> <p>The <code>StartDeliveryStreamEncryption</code> and <code>StopDeliveryStreamEncryption</code> operations have a combined limit of 25 calls per delivery stream per 24 hours. For example, you reach the limit if you call <code>StartDeliveryStreamEncryption</code> 13 times and <code>StopDeliveryStreamEncryption</code> 12 times for the same delivery stream in a 24-hour period.</p>
  ## 
  let valid = call_591089.validator(path, query, header, formData, body)
  let scheme = call_591089.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591089.url(scheme.get, call_591089.host, call_591089.base,
                         call_591089.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591089, url, valid)

proc call*(call_591090: Call_StopDeliveryStreamEncryption_591077; body: JsonNode): Recallable =
  ## stopDeliveryStreamEncryption
  ## <p>Disables server-side encryption (SSE) for the delivery stream. </p> <p>This operation is asynchronous. It returns immediately. When you invoke it, Kinesis Data Firehose first sets the status of the stream to <code>DISABLING</code>, and then to <code>DISABLED</code>. You can continue to read and write data to your stream while its status is <code>DISABLING</code>. It can take up to 5 seconds after the encryption status changes to <code>DISABLED</code> before all records written to the delivery stream are no longer subject to encryption. To find out whether a record or a batch of records was encrypted, check the response elements <a>PutRecordOutput$Encrypted</a> and <a>PutRecordBatchOutput$Encrypted</a>, respectively.</p> <p>To check the encryption state of a delivery stream, use <a>DescribeDeliveryStream</a>. </p> <p>The <code>StartDeliveryStreamEncryption</code> and <code>StopDeliveryStreamEncryption</code> operations have a combined limit of 25 calls per delivery stream per 24 hours. For example, you reach the limit if you call <code>StartDeliveryStreamEncryption</code> 13 times and <code>StopDeliveryStreamEncryption</code> 12 times for the same delivery stream in a 24-hour period.</p>
  ##   body: JObject (required)
  var body_591091 = newJObject()
  if body != nil:
    body_591091 = body
  result = call_591090.call(nil, nil, nil, nil, body_591091)

var stopDeliveryStreamEncryption* = Call_StopDeliveryStreamEncryption_591077(
    name: "stopDeliveryStreamEncryption", meth: HttpMethod.HttpPost,
    host: "firehose.amazonaws.com",
    route: "/#X-Amz-Target=Firehose_20150804.StopDeliveryStreamEncryption",
    validator: validate_StopDeliveryStreamEncryption_591078, base: "/",
    url: url_StopDeliveryStreamEncryption_591079,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagDeliveryStream_591092 = ref object of OpenApiRestCall_590364
proc url_TagDeliveryStream_591094(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagDeliveryStream_591093(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Adds or updates tags for the specified delivery stream. A tag is a key-value pair that you can define and assign to AWS resources. If you specify a tag that already exists, the tag value is replaced with the value that you specify in the request. Tags are metadata. For example, you can add friendly names and descriptions or other types of information that can help you distinguish the delivery stream. For more information about tags, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>. </p> <p>Each delivery stream can have up to 50 tags. </p> <p>This operation has a limit of five transactions per second per account. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591095 = header.getOrDefault("X-Amz-Target")
  valid_591095 = validateParameter(valid_591095, JString, required = true, default = newJString(
      "Firehose_20150804.TagDeliveryStream"))
  if valid_591095 != nil:
    section.add "X-Amz-Target", valid_591095
  var valid_591096 = header.getOrDefault("X-Amz-Signature")
  valid_591096 = validateParameter(valid_591096, JString, required = false,
                                 default = nil)
  if valid_591096 != nil:
    section.add "X-Amz-Signature", valid_591096
  var valid_591097 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591097 = validateParameter(valid_591097, JString, required = false,
                                 default = nil)
  if valid_591097 != nil:
    section.add "X-Amz-Content-Sha256", valid_591097
  var valid_591098 = header.getOrDefault("X-Amz-Date")
  valid_591098 = validateParameter(valid_591098, JString, required = false,
                                 default = nil)
  if valid_591098 != nil:
    section.add "X-Amz-Date", valid_591098
  var valid_591099 = header.getOrDefault("X-Amz-Credential")
  valid_591099 = validateParameter(valid_591099, JString, required = false,
                                 default = nil)
  if valid_591099 != nil:
    section.add "X-Amz-Credential", valid_591099
  var valid_591100 = header.getOrDefault("X-Amz-Security-Token")
  valid_591100 = validateParameter(valid_591100, JString, required = false,
                                 default = nil)
  if valid_591100 != nil:
    section.add "X-Amz-Security-Token", valid_591100
  var valid_591101 = header.getOrDefault("X-Amz-Algorithm")
  valid_591101 = validateParameter(valid_591101, JString, required = false,
                                 default = nil)
  if valid_591101 != nil:
    section.add "X-Amz-Algorithm", valid_591101
  var valid_591102 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591102 = validateParameter(valid_591102, JString, required = false,
                                 default = nil)
  if valid_591102 != nil:
    section.add "X-Amz-SignedHeaders", valid_591102
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591104: Call_TagDeliveryStream_591092; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds or updates tags for the specified delivery stream. A tag is a key-value pair that you can define and assign to AWS resources. If you specify a tag that already exists, the tag value is replaced with the value that you specify in the request. Tags are metadata. For example, you can add friendly names and descriptions or other types of information that can help you distinguish the delivery stream. For more information about tags, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>. </p> <p>Each delivery stream can have up to 50 tags. </p> <p>This operation has a limit of five transactions per second per account. </p>
  ## 
  let valid = call_591104.validator(path, query, header, formData, body)
  let scheme = call_591104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591104.url(scheme.get, call_591104.host, call_591104.base,
                         call_591104.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591104, url, valid)

proc call*(call_591105: Call_TagDeliveryStream_591092; body: JsonNode): Recallable =
  ## tagDeliveryStream
  ## <p>Adds or updates tags for the specified delivery stream. A tag is a key-value pair that you can define and assign to AWS resources. If you specify a tag that already exists, the tag value is replaced with the value that you specify in the request. Tags are metadata. For example, you can add friendly names and descriptions or other types of information that can help you distinguish the delivery stream. For more information about tags, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>. </p> <p>Each delivery stream can have up to 50 tags. </p> <p>This operation has a limit of five transactions per second per account. </p>
  ##   body: JObject (required)
  var body_591106 = newJObject()
  if body != nil:
    body_591106 = body
  result = call_591105.call(nil, nil, nil, nil, body_591106)

var tagDeliveryStream* = Call_TagDeliveryStream_591092(name: "tagDeliveryStream",
    meth: HttpMethod.HttpPost, host: "firehose.amazonaws.com",
    route: "/#X-Amz-Target=Firehose_20150804.TagDeliveryStream",
    validator: validate_TagDeliveryStream_591093, base: "/",
    url: url_TagDeliveryStream_591094, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagDeliveryStream_591107 = ref object of OpenApiRestCall_590364
proc url_UntagDeliveryStream_591109(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UntagDeliveryStream_591108(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Removes tags from the specified delivery stream. Removed tags are deleted, and you can't recover them after this operation successfully completes.</p> <p>If you specify a tag that doesn't exist, the operation ignores it.</p> <p>This operation has a limit of five transactions per second per account. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591110 = header.getOrDefault("X-Amz-Target")
  valid_591110 = validateParameter(valid_591110, JString, required = true, default = newJString(
      "Firehose_20150804.UntagDeliveryStream"))
  if valid_591110 != nil:
    section.add "X-Amz-Target", valid_591110
  var valid_591111 = header.getOrDefault("X-Amz-Signature")
  valid_591111 = validateParameter(valid_591111, JString, required = false,
                                 default = nil)
  if valid_591111 != nil:
    section.add "X-Amz-Signature", valid_591111
  var valid_591112 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591112 = validateParameter(valid_591112, JString, required = false,
                                 default = nil)
  if valid_591112 != nil:
    section.add "X-Amz-Content-Sha256", valid_591112
  var valid_591113 = header.getOrDefault("X-Amz-Date")
  valid_591113 = validateParameter(valid_591113, JString, required = false,
                                 default = nil)
  if valid_591113 != nil:
    section.add "X-Amz-Date", valid_591113
  var valid_591114 = header.getOrDefault("X-Amz-Credential")
  valid_591114 = validateParameter(valid_591114, JString, required = false,
                                 default = nil)
  if valid_591114 != nil:
    section.add "X-Amz-Credential", valid_591114
  var valid_591115 = header.getOrDefault("X-Amz-Security-Token")
  valid_591115 = validateParameter(valid_591115, JString, required = false,
                                 default = nil)
  if valid_591115 != nil:
    section.add "X-Amz-Security-Token", valid_591115
  var valid_591116 = header.getOrDefault("X-Amz-Algorithm")
  valid_591116 = validateParameter(valid_591116, JString, required = false,
                                 default = nil)
  if valid_591116 != nil:
    section.add "X-Amz-Algorithm", valid_591116
  var valid_591117 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591117 = validateParameter(valid_591117, JString, required = false,
                                 default = nil)
  if valid_591117 != nil:
    section.add "X-Amz-SignedHeaders", valid_591117
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591119: Call_UntagDeliveryStream_591107; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes tags from the specified delivery stream. Removed tags are deleted, and you can't recover them after this operation successfully completes.</p> <p>If you specify a tag that doesn't exist, the operation ignores it.</p> <p>This operation has a limit of five transactions per second per account. </p>
  ## 
  let valid = call_591119.validator(path, query, header, formData, body)
  let scheme = call_591119.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591119.url(scheme.get, call_591119.host, call_591119.base,
                         call_591119.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591119, url, valid)

proc call*(call_591120: Call_UntagDeliveryStream_591107; body: JsonNode): Recallable =
  ## untagDeliveryStream
  ## <p>Removes tags from the specified delivery stream. Removed tags are deleted, and you can't recover them after this operation successfully completes.</p> <p>If you specify a tag that doesn't exist, the operation ignores it.</p> <p>This operation has a limit of five transactions per second per account. </p>
  ##   body: JObject (required)
  var body_591121 = newJObject()
  if body != nil:
    body_591121 = body
  result = call_591120.call(nil, nil, nil, nil, body_591121)

var untagDeliveryStream* = Call_UntagDeliveryStream_591107(
    name: "untagDeliveryStream", meth: HttpMethod.HttpPost,
    host: "firehose.amazonaws.com",
    route: "/#X-Amz-Target=Firehose_20150804.UntagDeliveryStream",
    validator: validate_UntagDeliveryStream_591108, base: "/",
    url: url_UntagDeliveryStream_591109, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDestination_591122 = ref object of OpenApiRestCall_590364
proc url_UpdateDestination_591124(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateDestination_591123(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Updates the specified destination of the specified delivery stream.</p> <p>Use this operation to change the destination type (for example, to replace the Amazon S3 destination with Amazon Redshift) or change the parameters associated with a destination (for example, to change the bucket name of the Amazon S3 destination). The update might not occur immediately. The target delivery stream remains active while the configurations are updated, so data writes to the delivery stream can continue during this process. The updated configurations are usually effective within a few minutes.</p> <p>Switching between Amazon ES and other services is not supported. For an Amazon ES destination, you can only update to another Amazon ES destination.</p> <p>If the destination type is the same, Kinesis Data Firehose merges the configuration parameters specified with the destination configuration that already exists on the delivery stream. If any of the parameters are not specified in the call, the existing values are retained. For example, in the Amazon S3 destination, if <a>EncryptionConfiguration</a> is not specified, then the existing <code>EncryptionConfiguration</code> is maintained on the destination.</p> <p>If the destination type is not the same, for example, changing the destination from Amazon S3 to Amazon Redshift, Kinesis Data Firehose does not merge any parameters. In this case, all parameters must be specified.</p> <p>Kinesis Data Firehose uses <code>CurrentDeliveryStreamVersionId</code> to avoid race conditions and conflicting merges. This is a required field, and the service updates the configuration only if the existing configuration has a version ID that matches. After the update is applied successfully, the version ID is updated, and can be retrieved using <a>DescribeDeliveryStream</a>. Use the new version ID to set <code>CurrentDeliveryStreamVersionId</code> in the next call.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591125 = header.getOrDefault("X-Amz-Target")
  valid_591125 = validateParameter(valid_591125, JString, required = true, default = newJString(
      "Firehose_20150804.UpdateDestination"))
  if valid_591125 != nil:
    section.add "X-Amz-Target", valid_591125
  var valid_591126 = header.getOrDefault("X-Amz-Signature")
  valid_591126 = validateParameter(valid_591126, JString, required = false,
                                 default = nil)
  if valid_591126 != nil:
    section.add "X-Amz-Signature", valid_591126
  var valid_591127 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591127 = validateParameter(valid_591127, JString, required = false,
                                 default = nil)
  if valid_591127 != nil:
    section.add "X-Amz-Content-Sha256", valid_591127
  var valid_591128 = header.getOrDefault("X-Amz-Date")
  valid_591128 = validateParameter(valid_591128, JString, required = false,
                                 default = nil)
  if valid_591128 != nil:
    section.add "X-Amz-Date", valid_591128
  var valid_591129 = header.getOrDefault("X-Amz-Credential")
  valid_591129 = validateParameter(valid_591129, JString, required = false,
                                 default = nil)
  if valid_591129 != nil:
    section.add "X-Amz-Credential", valid_591129
  var valid_591130 = header.getOrDefault("X-Amz-Security-Token")
  valid_591130 = validateParameter(valid_591130, JString, required = false,
                                 default = nil)
  if valid_591130 != nil:
    section.add "X-Amz-Security-Token", valid_591130
  var valid_591131 = header.getOrDefault("X-Amz-Algorithm")
  valid_591131 = validateParameter(valid_591131, JString, required = false,
                                 default = nil)
  if valid_591131 != nil:
    section.add "X-Amz-Algorithm", valid_591131
  var valid_591132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591132 = validateParameter(valid_591132, JString, required = false,
                                 default = nil)
  if valid_591132 != nil:
    section.add "X-Amz-SignedHeaders", valid_591132
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591134: Call_UpdateDestination_591122; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified destination of the specified delivery stream.</p> <p>Use this operation to change the destination type (for example, to replace the Amazon S3 destination with Amazon Redshift) or change the parameters associated with a destination (for example, to change the bucket name of the Amazon S3 destination). The update might not occur immediately. The target delivery stream remains active while the configurations are updated, so data writes to the delivery stream can continue during this process. The updated configurations are usually effective within a few minutes.</p> <p>Switching between Amazon ES and other services is not supported. For an Amazon ES destination, you can only update to another Amazon ES destination.</p> <p>If the destination type is the same, Kinesis Data Firehose merges the configuration parameters specified with the destination configuration that already exists on the delivery stream. If any of the parameters are not specified in the call, the existing values are retained. For example, in the Amazon S3 destination, if <a>EncryptionConfiguration</a> is not specified, then the existing <code>EncryptionConfiguration</code> is maintained on the destination.</p> <p>If the destination type is not the same, for example, changing the destination from Amazon S3 to Amazon Redshift, Kinesis Data Firehose does not merge any parameters. In this case, all parameters must be specified.</p> <p>Kinesis Data Firehose uses <code>CurrentDeliveryStreamVersionId</code> to avoid race conditions and conflicting merges. This is a required field, and the service updates the configuration only if the existing configuration has a version ID that matches. After the update is applied successfully, the version ID is updated, and can be retrieved using <a>DescribeDeliveryStream</a>. Use the new version ID to set <code>CurrentDeliveryStreamVersionId</code> in the next call.</p>
  ## 
  let valid = call_591134.validator(path, query, header, formData, body)
  let scheme = call_591134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591134.url(scheme.get, call_591134.host, call_591134.base,
                         call_591134.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591134, url, valid)

proc call*(call_591135: Call_UpdateDestination_591122; body: JsonNode): Recallable =
  ## updateDestination
  ## <p>Updates the specified destination of the specified delivery stream.</p> <p>Use this operation to change the destination type (for example, to replace the Amazon S3 destination with Amazon Redshift) or change the parameters associated with a destination (for example, to change the bucket name of the Amazon S3 destination). The update might not occur immediately. The target delivery stream remains active while the configurations are updated, so data writes to the delivery stream can continue during this process. The updated configurations are usually effective within a few minutes.</p> <p>Switching between Amazon ES and other services is not supported. For an Amazon ES destination, you can only update to another Amazon ES destination.</p> <p>If the destination type is the same, Kinesis Data Firehose merges the configuration parameters specified with the destination configuration that already exists on the delivery stream. If any of the parameters are not specified in the call, the existing values are retained. For example, in the Amazon S3 destination, if <a>EncryptionConfiguration</a> is not specified, then the existing <code>EncryptionConfiguration</code> is maintained on the destination.</p> <p>If the destination type is not the same, for example, changing the destination from Amazon S3 to Amazon Redshift, Kinesis Data Firehose does not merge any parameters. In this case, all parameters must be specified.</p> <p>Kinesis Data Firehose uses <code>CurrentDeliveryStreamVersionId</code> to avoid race conditions and conflicting merges. This is a required field, and the service updates the configuration only if the existing configuration has a version ID that matches. After the update is applied successfully, the version ID is updated, and can be retrieved using <a>DescribeDeliveryStream</a>. Use the new version ID to set <code>CurrentDeliveryStreamVersionId</code> in the next call.</p>
  ##   body: JObject (required)
  var body_591136 = newJObject()
  if body != nil:
    body_591136 = body
  result = call_591135.call(nil, nil, nil, nil, body_591136)

var updateDestination* = Call_UpdateDestination_591122(name: "updateDestination",
    meth: HttpMethod.HttpPost, host: "firehose.amazonaws.com",
    route: "/#X-Amz-Target=Firehose_20150804.UpdateDestination",
    validator: validate_UpdateDestination_591123, base: "/",
    url: url_UpdateDestination_591124, schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc sign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", "")
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", "")
    region = os.getEnv("AWS_REGION", "")
  assert secret != "", "need secret key in env"
  assert access != "", "need access key in env"
  assert region != "", "need region in env"
  var
    normal: PathNormal
    url = normalizeUrl(recall.url, query, normalize = normal)
    scheme = parseEnum[Scheme](url.scheme)
  assert scheme in awsServers, "unknown scheme `" & $scheme & "`"
  assert region in awsServers[scheme], "unknown region `" & region & "`"
  url.hostname = awsServers[scheme][region]
  case awsServiceName.toLowerAscii
  of "s3":
    normal = PathNormal.S3
  else:
    normal = PathNormal.Default
  recall.headers["Host"] = url.hostname
  recall.headers["X-Amz-Date"] = date
  let
    algo = SHA256
    scope = credentialScope(region = region, service = awsServiceName, date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers, recall.body,
                             normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date, region = region,
                                 service = awsServiceName, sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.sign(input.getOrDefault("query"), SHA256)

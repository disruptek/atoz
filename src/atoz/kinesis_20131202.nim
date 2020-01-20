
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Kinesis
## version: 2013-12-02
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon Kinesis Data Streams Service API Reference</fullname> <p>Amazon Kinesis Data Streams is a managed service that scales elastically for real-time processing of streaming big data.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/kinesis/
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

  OpenApiRestCall_605589 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605589](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605589): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "kinesis.ap-northeast-1.amazonaws.com", "ap-southeast-1": "kinesis.ap-southeast-1.amazonaws.com",
                           "us-west-2": "kinesis.us-west-2.amazonaws.com",
                           "eu-west-2": "kinesis.eu-west-2.amazonaws.com", "ap-northeast-3": "kinesis.ap-northeast-3.amazonaws.com", "eu-central-1": "kinesis.eu-central-1.amazonaws.com",
                           "us-east-2": "kinesis.us-east-2.amazonaws.com",
                           "us-east-1": "kinesis.us-east-1.amazonaws.com", "cn-northwest-1": "kinesis.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "kinesis.ap-south-1.amazonaws.com",
                           "eu-north-1": "kinesis.eu-north-1.amazonaws.com", "ap-northeast-2": "kinesis.ap-northeast-2.amazonaws.com",
                           "us-west-1": "kinesis.us-west-1.amazonaws.com", "us-gov-east-1": "kinesis.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "kinesis.eu-west-3.amazonaws.com",
                           "cn-north-1": "kinesis.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "kinesis.sa-east-1.amazonaws.com",
                           "eu-west-1": "kinesis.eu-west-1.amazonaws.com", "us-gov-west-1": "kinesis.us-gov-west-1.amazonaws.com", "ap-southeast-2": "kinesis.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "kinesis.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "kinesis.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "kinesis.ap-southeast-1.amazonaws.com",
      "us-west-2": "kinesis.us-west-2.amazonaws.com",
      "eu-west-2": "kinesis.eu-west-2.amazonaws.com",
      "ap-northeast-3": "kinesis.ap-northeast-3.amazonaws.com",
      "eu-central-1": "kinesis.eu-central-1.amazonaws.com",
      "us-east-2": "kinesis.us-east-2.amazonaws.com",
      "us-east-1": "kinesis.us-east-1.amazonaws.com",
      "cn-northwest-1": "kinesis.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "kinesis.ap-south-1.amazonaws.com",
      "eu-north-1": "kinesis.eu-north-1.amazonaws.com",
      "ap-northeast-2": "kinesis.ap-northeast-2.amazonaws.com",
      "us-west-1": "kinesis.us-west-1.amazonaws.com",
      "us-gov-east-1": "kinesis.us-gov-east-1.amazonaws.com",
      "eu-west-3": "kinesis.eu-west-3.amazonaws.com",
      "cn-north-1": "kinesis.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "kinesis.sa-east-1.amazonaws.com",
      "eu-west-1": "kinesis.eu-west-1.amazonaws.com",
      "us-gov-west-1": "kinesis.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "kinesis.ap-southeast-2.amazonaws.com",
      "ca-central-1": "kinesis.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "kinesis"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AddTagsToStream_605927 = ref object of OpenApiRestCall_605589
proc url_AddTagsToStream_605929(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AddTagsToStream_605928(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Adds or updates tags for the specified Kinesis data stream. Each time you invoke this operation, you can specify up to 10 tags. If you want to add more than 10 tags to your stream, you can invoke this operation multiple times. In total, each stream can have up to 50 tags.</p> <p>If tags have already been assigned to the stream, <code>AddTagsToStream</code> overwrites any existing tags that correspond to the specified tag keys.</p> <p> <a>AddTagsToStream</a> has a limit of five transactions per second per account.</p>
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
  var valid_606054 = header.getOrDefault("X-Amz-Target")
  valid_606054 = validateParameter(valid_606054, JString, required = true, default = newJString(
      "Kinesis_20131202.AddTagsToStream"))
  if valid_606054 != nil:
    section.add "X-Amz-Target", valid_606054
  var valid_606055 = header.getOrDefault("X-Amz-Signature")
  valid_606055 = validateParameter(valid_606055, JString, required = false,
                                 default = nil)
  if valid_606055 != nil:
    section.add "X-Amz-Signature", valid_606055
  var valid_606056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606056 = validateParameter(valid_606056, JString, required = false,
                                 default = nil)
  if valid_606056 != nil:
    section.add "X-Amz-Content-Sha256", valid_606056
  var valid_606057 = header.getOrDefault("X-Amz-Date")
  valid_606057 = validateParameter(valid_606057, JString, required = false,
                                 default = nil)
  if valid_606057 != nil:
    section.add "X-Amz-Date", valid_606057
  var valid_606058 = header.getOrDefault("X-Amz-Credential")
  valid_606058 = validateParameter(valid_606058, JString, required = false,
                                 default = nil)
  if valid_606058 != nil:
    section.add "X-Amz-Credential", valid_606058
  var valid_606059 = header.getOrDefault("X-Amz-Security-Token")
  valid_606059 = validateParameter(valid_606059, JString, required = false,
                                 default = nil)
  if valid_606059 != nil:
    section.add "X-Amz-Security-Token", valid_606059
  var valid_606060 = header.getOrDefault("X-Amz-Algorithm")
  valid_606060 = validateParameter(valid_606060, JString, required = false,
                                 default = nil)
  if valid_606060 != nil:
    section.add "X-Amz-Algorithm", valid_606060
  var valid_606061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606061 = validateParameter(valid_606061, JString, required = false,
                                 default = nil)
  if valid_606061 != nil:
    section.add "X-Amz-SignedHeaders", valid_606061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606085: Call_AddTagsToStream_605927; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds or updates tags for the specified Kinesis data stream. Each time you invoke this operation, you can specify up to 10 tags. If you want to add more than 10 tags to your stream, you can invoke this operation multiple times. In total, each stream can have up to 50 tags.</p> <p>If tags have already been assigned to the stream, <code>AddTagsToStream</code> overwrites any existing tags that correspond to the specified tag keys.</p> <p> <a>AddTagsToStream</a> has a limit of five transactions per second per account.</p>
  ## 
  let valid = call_606085.validator(path, query, header, formData, body)
  let scheme = call_606085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606085.url(scheme.get, call_606085.host, call_606085.base,
                         call_606085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606085, url, valid)

proc call*(call_606156: Call_AddTagsToStream_605927; body: JsonNode): Recallable =
  ## addTagsToStream
  ## <p>Adds or updates tags for the specified Kinesis data stream. Each time you invoke this operation, you can specify up to 10 tags. If you want to add more than 10 tags to your stream, you can invoke this operation multiple times. In total, each stream can have up to 50 tags.</p> <p>If tags have already been assigned to the stream, <code>AddTagsToStream</code> overwrites any existing tags that correspond to the specified tag keys.</p> <p> <a>AddTagsToStream</a> has a limit of five transactions per second per account.</p>
  ##   body: JObject (required)
  var body_606157 = newJObject()
  if body != nil:
    body_606157 = body
  result = call_606156.call(nil, nil, nil, nil, body_606157)

var addTagsToStream* = Call_AddTagsToStream_605927(name: "addTagsToStream",
    meth: HttpMethod.HttpPost, host: "kinesis.amazonaws.com",
    route: "/#X-Amz-Target=Kinesis_20131202.AddTagsToStream",
    validator: validate_AddTagsToStream_605928, base: "/", url: url_AddTagsToStream_605929,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStream_606196 = ref object of OpenApiRestCall_605589
proc url_CreateStream_606198(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateStream_606197(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a Kinesis data stream. A stream captures and transports data records that are continuously emitted from different data sources or <i>producers</i>. Scale-out within a stream is explicitly supported by means of shards, which are uniquely identified groups of data records in a stream.</p> <p>You specify and control the number of shards that a stream is composed of. Each shard can support reads up to five transactions per second, up to a maximum data read total of 2 MB per second. Each shard can support writes up to 1,000 records per second, up to a maximum data write total of 1 MB per second. If the amount of data input increases or decreases, you can add or remove shards.</p> <p>The stream name identifies the stream. The name is scoped to the AWS account used by the application. It is also scoped by AWS Region. That is, two streams in two different accounts can have the same name, and two streams in the same account, but in two different Regions, can have the same name.</p> <p> <code>CreateStream</code> is an asynchronous operation. Upon receiving a <code>CreateStream</code> request, Kinesis Data Streams immediately returns and sets the stream status to <code>CREATING</code>. After the stream is created, Kinesis Data Streams sets the stream status to <code>ACTIVE</code>. You should perform read and write operations only on an <code>ACTIVE</code> stream. </p> <p>You receive a <code>LimitExceededException</code> when making a <code>CreateStream</code> request when you try to do one of the following:</p> <ul> <li> <p>Have more than five streams in the <code>CREATING</code> state at any point in time.</p> </li> <li> <p>Create more shards than are authorized for your account.</p> </li> </ul> <p>For the default shard limit for an AWS account, see <a href="http://docs.aws.amazon.com/kinesis/latest/dev/service-sizes-and-limits.html">Amazon Kinesis Data Streams Limits</a> in the <i>Amazon Kinesis Data Streams Developer Guide</i>. To increase this limit, <a href="http://docs.aws.amazon.com/general/latest/gr/aws_service_limits.html">contact AWS Support</a>.</p> <p>You can use <code>DescribeStream</code> to check the stream status, which is returned in <code>StreamStatus</code>.</p> <p> <a>CreateStream</a> has a limit of five transactions per second per account.</p>
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
  var valid_606199 = header.getOrDefault("X-Amz-Target")
  valid_606199 = validateParameter(valid_606199, JString, required = true, default = newJString(
      "Kinesis_20131202.CreateStream"))
  if valid_606199 != nil:
    section.add "X-Amz-Target", valid_606199
  var valid_606200 = header.getOrDefault("X-Amz-Signature")
  valid_606200 = validateParameter(valid_606200, JString, required = false,
                                 default = nil)
  if valid_606200 != nil:
    section.add "X-Amz-Signature", valid_606200
  var valid_606201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606201 = validateParameter(valid_606201, JString, required = false,
                                 default = nil)
  if valid_606201 != nil:
    section.add "X-Amz-Content-Sha256", valid_606201
  var valid_606202 = header.getOrDefault("X-Amz-Date")
  valid_606202 = validateParameter(valid_606202, JString, required = false,
                                 default = nil)
  if valid_606202 != nil:
    section.add "X-Amz-Date", valid_606202
  var valid_606203 = header.getOrDefault("X-Amz-Credential")
  valid_606203 = validateParameter(valid_606203, JString, required = false,
                                 default = nil)
  if valid_606203 != nil:
    section.add "X-Amz-Credential", valid_606203
  var valid_606204 = header.getOrDefault("X-Amz-Security-Token")
  valid_606204 = validateParameter(valid_606204, JString, required = false,
                                 default = nil)
  if valid_606204 != nil:
    section.add "X-Amz-Security-Token", valid_606204
  var valid_606205 = header.getOrDefault("X-Amz-Algorithm")
  valid_606205 = validateParameter(valid_606205, JString, required = false,
                                 default = nil)
  if valid_606205 != nil:
    section.add "X-Amz-Algorithm", valid_606205
  var valid_606206 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606206 = validateParameter(valid_606206, JString, required = false,
                                 default = nil)
  if valid_606206 != nil:
    section.add "X-Amz-SignedHeaders", valid_606206
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606208: Call_CreateStream_606196; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Kinesis data stream. A stream captures and transports data records that are continuously emitted from different data sources or <i>producers</i>. Scale-out within a stream is explicitly supported by means of shards, which are uniquely identified groups of data records in a stream.</p> <p>You specify and control the number of shards that a stream is composed of. Each shard can support reads up to five transactions per second, up to a maximum data read total of 2 MB per second. Each shard can support writes up to 1,000 records per second, up to a maximum data write total of 1 MB per second. If the amount of data input increases or decreases, you can add or remove shards.</p> <p>The stream name identifies the stream. The name is scoped to the AWS account used by the application. It is also scoped by AWS Region. That is, two streams in two different accounts can have the same name, and two streams in the same account, but in two different Regions, can have the same name.</p> <p> <code>CreateStream</code> is an asynchronous operation. Upon receiving a <code>CreateStream</code> request, Kinesis Data Streams immediately returns and sets the stream status to <code>CREATING</code>. After the stream is created, Kinesis Data Streams sets the stream status to <code>ACTIVE</code>. You should perform read and write operations only on an <code>ACTIVE</code> stream. </p> <p>You receive a <code>LimitExceededException</code> when making a <code>CreateStream</code> request when you try to do one of the following:</p> <ul> <li> <p>Have more than five streams in the <code>CREATING</code> state at any point in time.</p> </li> <li> <p>Create more shards than are authorized for your account.</p> </li> </ul> <p>For the default shard limit for an AWS account, see <a href="http://docs.aws.amazon.com/kinesis/latest/dev/service-sizes-and-limits.html">Amazon Kinesis Data Streams Limits</a> in the <i>Amazon Kinesis Data Streams Developer Guide</i>. To increase this limit, <a href="http://docs.aws.amazon.com/general/latest/gr/aws_service_limits.html">contact AWS Support</a>.</p> <p>You can use <code>DescribeStream</code> to check the stream status, which is returned in <code>StreamStatus</code>.</p> <p> <a>CreateStream</a> has a limit of five transactions per second per account.</p>
  ## 
  let valid = call_606208.validator(path, query, header, formData, body)
  let scheme = call_606208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606208.url(scheme.get, call_606208.host, call_606208.base,
                         call_606208.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606208, url, valid)

proc call*(call_606209: Call_CreateStream_606196; body: JsonNode): Recallable =
  ## createStream
  ## <p>Creates a Kinesis data stream. A stream captures and transports data records that are continuously emitted from different data sources or <i>producers</i>. Scale-out within a stream is explicitly supported by means of shards, which are uniquely identified groups of data records in a stream.</p> <p>You specify and control the number of shards that a stream is composed of. Each shard can support reads up to five transactions per second, up to a maximum data read total of 2 MB per second. Each shard can support writes up to 1,000 records per second, up to a maximum data write total of 1 MB per second. If the amount of data input increases or decreases, you can add or remove shards.</p> <p>The stream name identifies the stream. The name is scoped to the AWS account used by the application. It is also scoped by AWS Region. That is, two streams in two different accounts can have the same name, and two streams in the same account, but in two different Regions, can have the same name.</p> <p> <code>CreateStream</code> is an asynchronous operation. Upon receiving a <code>CreateStream</code> request, Kinesis Data Streams immediately returns and sets the stream status to <code>CREATING</code>. After the stream is created, Kinesis Data Streams sets the stream status to <code>ACTIVE</code>. You should perform read and write operations only on an <code>ACTIVE</code> stream. </p> <p>You receive a <code>LimitExceededException</code> when making a <code>CreateStream</code> request when you try to do one of the following:</p> <ul> <li> <p>Have more than five streams in the <code>CREATING</code> state at any point in time.</p> </li> <li> <p>Create more shards than are authorized for your account.</p> </li> </ul> <p>For the default shard limit for an AWS account, see <a href="http://docs.aws.amazon.com/kinesis/latest/dev/service-sizes-and-limits.html">Amazon Kinesis Data Streams Limits</a> in the <i>Amazon Kinesis Data Streams Developer Guide</i>. To increase this limit, <a href="http://docs.aws.amazon.com/general/latest/gr/aws_service_limits.html">contact AWS Support</a>.</p> <p>You can use <code>DescribeStream</code> to check the stream status, which is returned in <code>StreamStatus</code>.</p> <p> <a>CreateStream</a> has a limit of five transactions per second per account.</p>
  ##   body: JObject (required)
  var body_606210 = newJObject()
  if body != nil:
    body_606210 = body
  result = call_606209.call(nil, nil, nil, nil, body_606210)

var createStream* = Call_CreateStream_606196(name: "createStream",
    meth: HttpMethod.HttpPost, host: "kinesis.amazonaws.com",
    route: "/#X-Amz-Target=Kinesis_20131202.CreateStream",
    validator: validate_CreateStream_606197, base: "/", url: url_CreateStream_606198,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DecreaseStreamRetentionPeriod_606211 = ref object of OpenApiRestCall_605589
proc url_DecreaseStreamRetentionPeriod_606213(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DecreaseStreamRetentionPeriod_606212(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Decreases the Kinesis data stream's retention period, which is the length of time data records are accessible after they are added to the stream. The minimum value of a stream's retention period is 24 hours.</p> <p>This operation may result in lost data. For example, if the stream's retention period is 48 hours and is decreased to 24 hours, any data already in the stream that is older than 24 hours is inaccessible.</p>
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
  var valid_606214 = header.getOrDefault("X-Amz-Target")
  valid_606214 = validateParameter(valid_606214, JString, required = true, default = newJString(
      "Kinesis_20131202.DecreaseStreamRetentionPeriod"))
  if valid_606214 != nil:
    section.add "X-Amz-Target", valid_606214
  var valid_606215 = header.getOrDefault("X-Amz-Signature")
  valid_606215 = validateParameter(valid_606215, JString, required = false,
                                 default = nil)
  if valid_606215 != nil:
    section.add "X-Amz-Signature", valid_606215
  var valid_606216 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606216 = validateParameter(valid_606216, JString, required = false,
                                 default = nil)
  if valid_606216 != nil:
    section.add "X-Amz-Content-Sha256", valid_606216
  var valid_606217 = header.getOrDefault("X-Amz-Date")
  valid_606217 = validateParameter(valid_606217, JString, required = false,
                                 default = nil)
  if valid_606217 != nil:
    section.add "X-Amz-Date", valid_606217
  var valid_606218 = header.getOrDefault("X-Amz-Credential")
  valid_606218 = validateParameter(valid_606218, JString, required = false,
                                 default = nil)
  if valid_606218 != nil:
    section.add "X-Amz-Credential", valid_606218
  var valid_606219 = header.getOrDefault("X-Amz-Security-Token")
  valid_606219 = validateParameter(valid_606219, JString, required = false,
                                 default = nil)
  if valid_606219 != nil:
    section.add "X-Amz-Security-Token", valid_606219
  var valid_606220 = header.getOrDefault("X-Amz-Algorithm")
  valid_606220 = validateParameter(valid_606220, JString, required = false,
                                 default = nil)
  if valid_606220 != nil:
    section.add "X-Amz-Algorithm", valid_606220
  var valid_606221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606221 = validateParameter(valid_606221, JString, required = false,
                                 default = nil)
  if valid_606221 != nil:
    section.add "X-Amz-SignedHeaders", valid_606221
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606223: Call_DecreaseStreamRetentionPeriod_606211; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Decreases the Kinesis data stream's retention period, which is the length of time data records are accessible after they are added to the stream. The minimum value of a stream's retention period is 24 hours.</p> <p>This operation may result in lost data. For example, if the stream's retention period is 48 hours and is decreased to 24 hours, any data already in the stream that is older than 24 hours is inaccessible.</p>
  ## 
  let valid = call_606223.validator(path, query, header, formData, body)
  let scheme = call_606223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606223.url(scheme.get, call_606223.host, call_606223.base,
                         call_606223.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606223, url, valid)

proc call*(call_606224: Call_DecreaseStreamRetentionPeriod_606211; body: JsonNode): Recallable =
  ## decreaseStreamRetentionPeriod
  ## <p>Decreases the Kinesis data stream's retention period, which is the length of time data records are accessible after they are added to the stream. The minimum value of a stream's retention period is 24 hours.</p> <p>This operation may result in lost data. For example, if the stream's retention period is 48 hours and is decreased to 24 hours, any data already in the stream that is older than 24 hours is inaccessible.</p>
  ##   body: JObject (required)
  var body_606225 = newJObject()
  if body != nil:
    body_606225 = body
  result = call_606224.call(nil, nil, nil, nil, body_606225)

var decreaseStreamRetentionPeriod* = Call_DecreaseStreamRetentionPeriod_606211(
    name: "decreaseStreamRetentionPeriod", meth: HttpMethod.HttpPost,
    host: "kinesis.amazonaws.com",
    route: "/#X-Amz-Target=Kinesis_20131202.DecreaseStreamRetentionPeriod",
    validator: validate_DecreaseStreamRetentionPeriod_606212, base: "/",
    url: url_DecreaseStreamRetentionPeriod_606213,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteStream_606226 = ref object of OpenApiRestCall_605589
proc url_DeleteStream_606228(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteStream_606227(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes a Kinesis data stream and all its shards and data. You must shut down any applications that are operating on the stream before you delete the stream. If an application attempts to operate on a deleted stream, it receives the exception <code>ResourceNotFoundException</code>.</p> <p>If the stream is in the <code>ACTIVE</code> state, you can delete it. After a <code>DeleteStream</code> request, the specified stream is in the <code>DELETING</code> state until Kinesis Data Streams completes the deletion.</p> <p> <b>Note:</b> Kinesis Data Streams might continue to accept data read and write operations, such as <a>PutRecord</a>, <a>PutRecords</a>, and <a>GetRecords</a>, on a stream in the <code>DELETING</code> state until the stream deletion is complete.</p> <p>When you delete a stream, any shards in that stream are also deleted, and any tags are dissociated from the stream.</p> <p>You can use the <a>DescribeStream</a> operation to check the state of the stream, which is returned in <code>StreamStatus</code>.</p> <p> <a>DeleteStream</a> has a limit of five transactions per second per account.</p>
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
  var valid_606229 = header.getOrDefault("X-Amz-Target")
  valid_606229 = validateParameter(valid_606229, JString, required = true, default = newJString(
      "Kinesis_20131202.DeleteStream"))
  if valid_606229 != nil:
    section.add "X-Amz-Target", valid_606229
  var valid_606230 = header.getOrDefault("X-Amz-Signature")
  valid_606230 = validateParameter(valid_606230, JString, required = false,
                                 default = nil)
  if valid_606230 != nil:
    section.add "X-Amz-Signature", valid_606230
  var valid_606231 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606231 = validateParameter(valid_606231, JString, required = false,
                                 default = nil)
  if valid_606231 != nil:
    section.add "X-Amz-Content-Sha256", valid_606231
  var valid_606232 = header.getOrDefault("X-Amz-Date")
  valid_606232 = validateParameter(valid_606232, JString, required = false,
                                 default = nil)
  if valid_606232 != nil:
    section.add "X-Amz-Date", valid_606232
  var valid_606233 = header.getOrDefault("X-Amz-Credential")
  valid_606233 = validateParameter(valid_606233, JString, required = false,
                                 default = nil)
  if valid_606233 != nil:
    section.add "X-Amz-Credential", valid_606233
  var valid_606234 = header.getOrDefault("X-Amz-Security-Token")
  valid_606234 = validateParameter(valid_606234, JString, required = false,
                                 default = nil)
  if valid_606234 != nil:
    section.add "X-Amz-Security-Token", valid_606234
  var valid_606235 = header.getOrDefault("X-Amz-Algorithm")
  valid_606235 = validateParameter(valid_606235, JString, required = false,
                                 default = nil)
  if valid_606235 != nil:
    section.add "X-Amz-Algorithm", valid_606235
  var valid_606236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606236 = validateParameter(valid_606236, JString, required = false,
                                 default = nil)
  if valid_606236 != nil:
    section.add "X-Amz-SignedHeaders", valid_606236
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606238: Call_DeleteStream_606226; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a Kinesis data stream and all its shards and data. You must shut down any applications that are operating on the stream before you delete the stream. If an application attempts to operate on a deleted stream, it receives the exception <code>ResourceNotFoundException</code>.</p> <p>If the stream is in the <code>ACTIVE</code> state, you can delete it. After a <code>DeleteStream</code> request, the specified stream is in the <code>DELETING</code> state until Kinesis Data Streams completes the deletion.</p> <p> <b>Note:</b> Kinesis Data Streams might continue to accept data read and write operations, such as <a>PutRecord</a>, <a>PutRecords</a>, and <a>GetRecords</a>, on a stream in the <code>DELETING</code> state until the stream deletion is complete.</p> <p>When you delete a stream, any shards in that stream are also deleted, and any tags are dissociated from the stream.</p> <p>You can use the <a>DescribeStream</a> operation to check the state of the stream, which is returned in <code>StreamStatus</code>.</p> <p> <a>DeleteStream</a> has a limit of five transactions per second per account.</p>
  ## 
  let valid = call_606238.validator(path, query, header, formData, body)
  let scheme = call_606238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606238.url(scheme.get, call_606238.host, call_606238.base,
                         call_606238.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606238, url, valid)

proc call*(call_606239: Call_DeleteStream_606226; body: JsonNode): Recallable =
  ## deleteStream
  ## <p>Deletes a Kinesis data stream and all its shards and data. You must shut down any applications that are operating on the stream before you delete the stream. If an application attempts to operate on a deleted stream, it receives the exception <code>ResourceNotFoundException</code>.</p> <p>If the stream is in the <code>ACTIVE</code> state, you can delete it. After a <code>DeleteStream</code> request, the specified stream is in the <code>DELETING</code> state until Kinesis Data Streams completes the deletion.</p> <p> <b>Note:</b> Kinesis Data Streams might continue to accept data read and write operations, such as <a>PutRecord</a>, <a>PutRecords</a>, and <a>GetRecords</a>, on a stream in the <code>DELETING</code> state until the stream deletion is complete.</p> <p>When you delete a stream, any shards in that stream are also deleted, and any tags are dissociated from the stream.</p> <p>You can use the <a>DescribeStream</a> operation to check the state of the stream, which is returned in <code>StreamStatus</code>.</p> <p> <a>DeleteStream</a> has a limit of five transactions per second per account.</p>
  ##   body: JObject (required)
  var body_606240 = newJObject()
  if body != nil:
    body_606240 = body
  result = call_606239.call(nil, nil, nil, nil, body_606240)

var deleteStream* = Call_DeleteStream_606226(name: "deleteStream",
    meth: HttpMethod.HttpPost, host: "kinesis.amazonaws.com",
    route: "/#X-Amz-Target=Kinesis_20131202.DeleteStream",
    validator: validate_DeleteStream_606227, base: "/", url: url_DeleteStream_606228,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterStreamConsumer_606241 = ref object of OpenApiRestCall_605589
proc url_DeregisterStreamConsumer_606243(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeregisterStreamConsumer_606242(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>To deregister a consumer, provide its ARN. Alternatively, you can provide the ARN of the data stream and the name you gave the consumer when you registered it. You may also provide all three parameters, as long as they don't conflict with each other. If you don't know the name or ARN of the consumer that you want to deregister, you can use the <a>ListStreamConsumers</a> operation to get a list of the descriptions of all the consumers that are currently registered with a given data stream. The description of a consumer contains its name and ARN.</p> <p>This operation has a limit of five transactions per second per account.</p>
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
  var valid_606244 = header.getOrDefault("X-Amz-Target")
  valid_606244 = validateParameter(valid_606244, JString, required = true, default = newJString(
      "Kinesis_20131202.DeregisterStreamConsumer"))
  if valid_606244 != nil:
    section.add "X-Amz-Target", valid_606244
  var valid_606245 = header.getOrDefault("X-Amz-Signature")
  valid_606245 = validateParameter(valid_606245, JString, required = false,
                                 default = nil)
  if valid_606245 != nil:
    section.add "X-Amz-Signature", valid_606245
  var valid_606246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606246 = validateParameter(valid_606246, JString, required = false,
                                 default = nil)
  if valid_606246 != nil:
    section.add "X-Amz-Content-Sha256", valid_606246
  var valid_606247 = header.getOrDefault("X-Amz-Date")
  valid_606247 = validateParameter(valid_606247, JString, required = false,
                                 default = nil)
  if valid_606247 != nil:
    section.add "X-Amz-Date", valid_606247
  var valid_606248 = header.getOrDefault("X-Amz-Credential")
  valid_606248 = validateParameter(valid_606248, JString, required = false,
                                 default = nil)
  if valid_606248 != nil:
    section.add "X-Amz-Credential", valid_606248
  var valid_606249 = header.getOrDefault("X-Amz-Security-Token")
  valid_606249 = validateParameter(valid_606249, JString, required = false,
                                 default = nil)
  if valid_606249 != nil:
    section.add "X-Amz-Security-Token", valid_606249
  var valid_606250 = header.getOrDefault("X-Amz-Algorithm")
  valid_606250 = validateParameter(valid_606250, JString, required = false,
                                 default = nil)
  if valid_606250 != nil:
    section.add "X-Amz-Algorithm", valid_606250
  var valid_606251 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606251 = validateParameter(valid_606251, JString, required = false,
                                 default = nil)
  if valid_606251 != nil:
    section.add "X-Amz-SignedHeaders", valid_606251
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606253: Call_DeregisterStreamConsumer_606241; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>To deregister a consumer, provide its ARN. Alternatively, you can provide the ARN of the data stream and the name you gave the consumer when you registered it. You may also provide all three parameters, as long as they don't conflict with each other. If you don't know the name or ARN of the consumer that you want to deregister, you can use the <a>ListStreamConsumers</a> operation to get a list of the descriptions of all the consumers that are currently registered with a given data stream. The description of a consumer contains its name and ARN.</p> <p>This operation has a limit of five transactions per second per account.</p>
  ## 
  let valid = call_606253.validator(path, query, header, formData, body)
  let scheme = call_606253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606253.url(scheme.get, call_606253.host, call_606253.base,
                         call_606253.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606253, url, valid)

proc call*(call_606254: Call_DeregisterStreamConsumer_606241; body: JsonNode): Recallable =
  ## deregisterStreamConsumer
  ## <p>To deregister a consumer, provide its ARN. Alternatively, you can provide the ARN of the data stream and the name you gave the consumer when you registered it. You may also provide all three parameters, as long as they don't conflict with each other. If you don't know the name or ARN of the consumer that you want to deregister, you can use the <a>ListStreamConsumers</a> operation to get a list of the descriptions of all the consumers that are currently registered with a given data stream. The description of a consumer contains its name and ARN.</p> <p>This operation has a limit of five transactions per second per account.</p>
  ##   body: JObject (required)
  var body_606255 = newJObject()
  if body != nil:
    body_606255 = body
  result = call_606254.call(nil, nil, nil, nil, body_606255)

var deregisterStreamConsumer* = Call_DeregisterStreamConsumer_606241(
    name: "deregisterStreamConsumer", meth: HttpMethod.HttpPost,
    host: "kinesis.amazonaws.com",
    route: "/#X-Amz-Target=Kinesis_20131202.DeregisterStreamConsumer",
    validator: validate_DeregisterStreamConsumer_606242, base: "/",
    url: url_DeregisterStreamConsumer_606243, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLimits_606256 = ref object of OpenApiRestCall_605589
proc url_DescribeLimits_606258(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeLimits_606257(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Describes the shard limits and usage for the account.</p> <p>If you update your account limits, the old limits might be returned for a few minutes.</p> <p>This operation has a limit of one transaction per second per account.</p>
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
  var valid_606259 = header.getOrDefault("X-Amz-Target")
  valid_606259 = validateParameter(valid_606259, JString, required = true, default = newJString(
      "Kinesis_20131202.DescribeLimits"))
  if valid_606259 != nil:
    section.add "X-Amz-Target", valid_606259
  var valid_606260 = header.getOrDefault("X-Amz-Signature")
  valid_606260 = validateParameter(valid_606260, JString, required = false,
                                 default = nil)
  if valid_606260 != nil:
    section.add "X-Amz-Signature", valid_606260
  var valid_606261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606261 = validateParameter(valid_606261, JString, required = false,
                                 default = nil)
  if valid_606261 != nil:
    section.add "X-Amz-Content-Sha256", valid_606261
  var valid_606262 = header.getOrDefault("X-Amz-Date")
  valid_606262 = validateParameter(valid_606262, JString, required = false,
                                 default = nil)
  if valid_606262 != nil:
    section.add "X-Amz-Date", valid_606262
  var valid_606263 = header.getOrDefault("X-Amz-Credential")
  valid_606263 = validateParameter(valid_606263, JString, required = false,
                                 default = nil)
  if valid_606263 != nil:
    section.add "X-Amz-Credential", valid_606263
  var valid_606264 = header.getOrDefault("X-Amz-Security-Token")
  valid_606264 = validateParameter(valid_606264, JString, required = false,
                                 default = nil)
  if valid_606264 != nil:
    section.add "X-Amz-Security-Token", valid_606264
  var valid_606265 = header.getOrDefault("X-Amz-Algorithm")
  valid_606265 = validateParameter(valid_606265, JString, required = false,
                                 default = nil)
  if valid_606265 != nil:
    section.add "X-Amz-Algorithm", valid_606265
  var valid_606266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606266 = validateParameter(valid_606266, JString, required = false,
                                 default = nil)
  if valid_606266 != nil:
    section.add "X-Amz-SignedHeaders", valid_606266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606268: Call_DescribeLimits_606256; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the shard limits and usage for the account.</p> <p>If you update your account limits, the old limits might be returned for a few minutes.</p> <p>This operation has a limit of one transaction per second per account.</p>
  ## 
  let valid = call_606268.validator(path, query, header, formData, body)
  let scheme = call_606268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606268.url(scheme.get, call_606268.host, call_606268.base,
                         call_606268.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606268, url, valid)

proc call*(call_606269: Call_DescribeLimits_606256; body: JsonNode): Recallable =
  ## describeLimits
  ## <p>Describes the shard limits and usage for the account.</p> <p>If you update your account limits, the old limits might be returned for a few minutes.</p> <p>This operation has a limit of one transaction per second per account.</p>
  ##   body: JObject (required)
  var body_606270 = newJObject()
  if body != nil:
    body_606270 = body
  result = call_606269.call(nil, nil, nil, nil, body_606270)

var describeLimits* = Call_DescribeLimits_606256(name: "describeLimits",
    meth: HttpMethod.HttpPost, host: "kinesis.amazonaws.com",
    route: "/#X-Amz-Target=Kinesis_20131202.DescribeLimits",
    validator: validate_DescribeLimits_606257, base: "/", url: url_DescribeLimits_606258,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeStream_606271 = ref object of OpenApiRestCall_605589
proc url_DescribeStream_606273(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeStream_606272(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Describes the specified Kinesis data stream.</p> <p>The information returned includes the stream name, Amazon Resource Name (ARN), creation time, enhanced metric configuration, and shard map. The shard map is an array of shard objects. For each shard object, there is the hash key and sequence number ranges that the shard spans, and the IDs of any earlier shards that played in a role in creating the shard. Every record ingested in the stream is identified by a sequence number, which is assigned when the record is put into the stream.</p> <p>You can limit the number of shards returned by each call. For more information, see <a href="http://docs.aws.amazon.com/kinesis/latest/dev/kinesis-using-sdk-java-retrieve-shards.html">Retrieving Shards from a Stream</a> in the <i>Amazon Kinesis Data Streams Developer Guide</i>.</p> <p>There are no guarantees about the chronological order shards returned. To process shards in chronological order, use the ID of the parent shard to track the lineage to the oldest shard.</p> <p>This operation has a limit of 10 transactions per second per account.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Limit: JString
  ##        : Pagination limit
  ##   ExclusiveStartShardId: JString
  ##                        : Pagination token
  section = newJObject()
  var valid_606274 = query.getOrDefault("Limit")
  valid_606274 = validateParameter(valid_606274, JString, required = false,
                                 default = nil)
  if valid_606274 != nil:
    section.add "Limit", valid_606274
  var valid_606275 = query.getOrDefault("ExclusiveStartShardId")
  valid_606275 = validateParameter(valid_606275, JString, required = false,
                                 default = nil)
  if valid_606275 != nil:
    section.add "ExclusiveStartShardId", valid_606275
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
  var valid_606276 = header.getOrDefault("X-Amz-Target")
  valid_606276 = validateParameter(valid_606276, JString, required = true, default = newJString(
      "Kinesis_20131202.DescribeStream"))
  if valid_606276 != nil:
    section.add "X-Amz-Target", valid_606276
  var valid_606277 = header.getOrDefault("X-Amz-Signature")
  valid_606277 = validateParameter(valid_606277, JString, required = false,
                                 default = nil)
  if valid_606277 != nil:
    section.add "X-Amz-Signature", valid_606277
  var valid_606278 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606278 = validateParameter(valid_606278, JString, required = false,
                                 default = nil)
  if valid_606278 != nil:
    section.add "X-Amz-Content-Sha256", valid_606278
  var valid_606279 = header.getOrDefault("X-Amz-Date")
  valid_606279 = validateParameter(valid_606279, JString, required = false,
                                 default = nil)
  if valid_606279 != nil:
    section.add "X-Amz-Date", valid_606279
  var valid_606280 = header.getOrDefault("X-Amz-Credential")
  valid_606280 = validateParameter(valid_606280, JString, required = false,
                                 default = nil)
  if valid_606280 != nil:
    section.add "X-Amz-Credential", valid_606280
  var valid_606281 = header.getOrDefault("X-Amz-Security-Token")
  valid_606281 = validateParameter(valid_606281, JString, required = false,
                                 default = nil)
  if valid_606281 != nil:
    section.add "X-Amz-Security-Token", valid_606281
  var valid_606282 = header.getOrDefault("X-Amz-Algorithm")
  valid_606282 = validateParameter(valid_606282, JString, required = false,
                                 default = nil)
  if valid_606282 != nil:
    section.add "X-Amz-Algorithm", valid_606282
  var valid_606283 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606283 = validateParameter(valid_606283, JString, required = false,
                                 default = nil)
  if valid_606283 != nil:
    section.add "X-Amz-SignedHeaders", valid_606283
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606285: Call_DescribeStream_606271; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified Kinesis data stream.</p> <p>The information returned includes the stream name, Amazon Resource Name (ARN), creation time, enhanced metric configuration, and shard map. The shard map is an array of shard objects. For each shard object, there is the hash key and sequence number ranges that the shard spans, and the IDs of any earlier shards that played in a role in creating the shard. Every record ingested in the stream is identified by a sequence number, which is assigned when the record is put into the stream.</p> <p>You can limit the number of shards returned by each call. For more information, see <a href="http://docs.aws.amazon.com/kinesis/latest/dev/kinesis-using-sdk-java-retrieve-shards.html">Retrieving Shards from a Stream</a> in the <i>Amazon Kinesis Data Streams Developer Guide</i>.</p> <p>There are no guarantees about the chronological order shards returned. To process shards in chronological order, use the ID of the parent shard to track the lineage to the oldest shard.</p> <p>This operation has a limit of 10 transactions per second per account.</p>
  ## 
  let valid = call_606285.validator(path, query, header, formData, body)
  let scheme = call_606285.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606285.url(scheme.get, call_606285.host, call_606285.base,
                         call_606285.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606285, url, valid)

proc call*(call_606286: Call_DescribeStream_606271; body: JsonNode;
          Limit: string = ""; ExclusiveStartShardId: string = ""): Recallable =
  ## describeStream
  ## <p>Describes the specified Kinesis data stream.</p> <p>The information returned includes the stream name, Amazon Resource Name (ARN), creation time, enhanced metric configuration, and shard map. The shard map is an array of shard objects. For each shard object, there is the hash key and sequence number ranges that the shard spans, and the IDs of any earlier shards that played in a role in creating the shard. Every record ingested in the stream is identified by a sequence number, which is assigned when the record is put into the stream.</p> <p>You can limit the number of shards returned by each call. For more information, see <a href="http://docs.aws.amazon.com/kinesis/latest/dev/kinesis-using-sdk-java-retrieve-shards.html">Retrieving Shards from a Stream</a> in the <i>Amazon Kinesis Data Streams Developer Guide</i>.</p> <p>There are no guarantees about the chronological order shards returned. To process shards in chronological order, use the ID of the parent shard to track the lineage to the oldest shard.</p> <p>This operation has a limit of 10 transactions per second per account.</p>
  ##   Limit: string
  ##        : Pagination limit
  ##   ExclusiveStartShardId: string
  ##                        : Pagination token
  ##   body: JObject (required)
  var query_606287 = newJObject()
  var body_606288 = newJObject()
  add(query_606287, "Limit", newJString(Limit))
  add(query_606287, "ExclusiveStartShardId", newJString(ExclusiveStartShardId))
  if body != nil:
    body_606288 = body
  result = call_606286.call(nil, query_606287, nil, nil, body_606288)

var describeStream* = Call_DescribeStream_606271(name: "describeStream",
    meth: HttpMethod.HttpPost, host: "kinesis.amazonaws.com",
    route: "/#X-Amz-Target=Kinesis_20131202.DescribeStream",
    validator: validate_DescribeStream_606272, base: "/", url: url_DescribeStream_606273,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeStreamConsumer_606290 = ref object of OpenApiRestCall_605589
proc url_DescribeStreamConsumer_606292(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeStreamConsumer_606291(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>To get the description of a registered consumer, provide the ARN of the consumer. Alternatively, you can provide the ARN of the data stream and the name you gave the consumer when you registered it. You may also provide all three parameters, as long as they don't conflict with each other. If you don't know the name or ARN of the consumer that you want to describe, you can use the <a>ListStreamConsumers</a> operation to get a list of the descriptions of all the consumers that are currently registered with a given data stream.</p> <p>This operation has a limit of 20 transactions per second per account.</p>
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
  var valid_606293 = header.getOrDefault("X-Amz-Target")
  valid_606293 = validateParameter(valid_606293, JString, required = true, default = newJString(
      "Kinesis_20131202.DescribeStreamConsumer"))
  if valid_606293 != nil:
    section.add "X-Amz-Target", valid_606293
  var valid_606294 = header.getOrDefault("X-Amz-Signature")
  valid_606294 = validateParameter(valid_606294, JString, required = false,
                                 default = nil)
  if valid_606294 != nil:
    section.add "X-Amz-Signature", valid_606294
  var valid_606295 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606295 = validateParameter(valid_606295, JString, required = false,
                                 default = nil)
  if valid_606295 != nil:
    section.add "X-Amz-Content-Sha256", valid_606295
  var valid_606296 = header.getOrDefault("X-Amz-Date")
  valid_606296 = validateParameter(valid_606296, JString, required = false,
                                 default = nil)
  if valid_606296 != nil:
    section.add "X-Amz-Date", valid_606296
  var valid_606297 = header.getOrDefault("X-Amz-Credential")
  valid_606297 = validateParameter(valid_606297, JString, required = false,
                                 default = nil)
  if valid_606297 != nil:
    section.add "X-Amz-Credential", valid_606297
  var valid_606298 = header.getOrDefault("X-Amz-Security-Token")
  valid_606298 = validateParameter(valid_606298, JString, required = false,
                                 default = nil)
  if valid_606298 != nil:
    section.add "X-Amz-Security-Token", valid_606298
  var valid_606299 = header.getOrDefault("X-Amz-Algorithm")
  valid_606299 = validateParameter(valid_606299, JString, required = false,
                                 default = nil)
  if valid_606299 != nil:
    section.add "X-Amz-Algorithm", valid_606299
  var valid_606300 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606300 = validateParameter(valid_606300, JString, required = false,
                                 default = nil)
  if valid_606300 != nil:
    section.add "X-Amz-SignedHeaders", valid_606300
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606302: Call_DescribeStreamConsumer_606290; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>To get the description of a registered consumer, provide the ARN of the consumer. Alternatively, you can provide the ARN of the data stream and the name you gave the consumer when you registered it. You may also provide all three parameters, as long as they don't conflict with each other. If you don't know the name or ARN of the consumer that you want to describe, you can use the <a>ListStreamConsumers</a> operation to get a list of the descriptions of all the consumers that are currently registered with a given data stream.</p> <p>This operation has a limit of 20 transactions per second per account.</p>
  ## 
  let valid = call_606302.validator(path, query, header, formData, body)
  let scheme = call_606302.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606302.url(scheme.get, call_606302.host, call_606302.base,
                         call_606302.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606302, url, valid)

proc call*(call_606303: Call_DescribeStreamConsumer_606290; body: JsonNode): Recallable =
  ## describeStreamConsumer
  ## <p>To get the description of a registered consumer, provide the ARN of the consumer. Alternatively, you can provide the ARN of the data stream and the name you gave the consumer when you registered it. You may also provide all three parameters, as long as they don't conflict with each other. If you don't know the name or ARN of the consumer that you want to describe, you can use the <a>ListStreamConsumers</a> operation to get a list of the descriptions of all the consumers that are currently registered with a given data stream.</p> <p>This operation has a limit of 20 transactions per second per account.</p>
  ##   body: JObject (required)
  var body_606304 = newJObject()
  if body != nil:
    body_606304 = body
  result = call_606303.call(nil, nil, nil, nil, body_606304)

var describeStreamConsumer* = Call_DescribeStreamConsumer_606290(
    name: "describeStreamConsumer", meth: HttpMethod.HttpPost,
    host: "kinesis.amazonaws.com",
    route: "/#X-Amz-Target=Kinesis_20131202.DescribeStreamConsumer",
    validator: validate_DescribeStreamConsumer_606291, base: "/",
    url: url_DescribeStreamConsumer_606292, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeStreamSummary_606305 = ref object of OpenApiRestCall_605589
proc url_DescribeStreamSummary_606307(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeStreamSummary_606306(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Provides a summarized description of the specified Kinesis data stream without the shard list.</p> <p>The information returned includes the stream name, Amazon Resource Name (ARN), status, record retention period, approximate creation time, monitoring, encryption details, and open shard count. </p>
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
  var valid_606308 = header.getOrDefault("X-Amz-Target")
  valid_606308 = validateParameter(valid_606308, JString, required = true, default = newJString(
      "Kinesis_20131202.DescribeStreamSummary"))
  if valid_606308 != nil:
    section.add "X-Amz-Target", valid_606308
  var valid_606309 = header.getOrDefault("X-Amz-Signature")
  valid_606309 = validateParameter(valid_606309, JString, required = false,
                                 default = nil)
  if valid_606309 != nil:
    section.add "X-Amz-Signature", valid_606309
  var valid_606310 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606310 = validateParameter(valid_606310, JString, required = false,
                                 default = nil)
  if valid_606310 != nil:
    section.add "X-Amz-Content-Sha256", valid_606310
  var valid_606311 = header.getOrDefault("X-Amz-Date")
  valid_606311 = validateParameter(valid_606311, JString, required = false,
                                 default = nil)
  if valid_606311 != nil:
    section.add "X-Amz-Date", valid_606311
  var valid_606312 = header.getOrDefault("X-Amz-Credential")
  valid_606312 = validateParameter(valid_606312, JString, required = false,
                                 default = nil)
  if valid_606312 != nil:
    section.add "X-Amz-Credential", valid_606312
  var valid_606313 = header.getOrDefault("X-Amz-Security-Token")
  valid_606313 = validateParameter(valid_606313, JString, required = false,
                                 default = nil)
  if valid_606313 != nil:
    section.add "X-Amz-Security-Token", valid_606313
  var valid_606314 = header.getOrDefault("X-Amz-Algorithm")
  valid_606314 = validateParameter(valid_606314, JString, required = false,
                                 default = nil)
  if valid_606314 != nil:
    section.add "X-Amz-Algorithm", valid_606314
  var valid_606315 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606315 = validateParameter(valid_606315, JString, required = false,
                                 default = nil)
  if valid_606315 != nil:
    section.add "X-Amz-SignedHeaders", valid_606315
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606317: Call_DescribeStreamSummary_606305; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Provides a summarized description of the specified Kinesis data stream without the shard list.</p> <p>The information returned includes the stream name, Amazon Resource Name (ARN), status, record retention period, approximate creation time, monitoring, encryption details, and open shard count. </p>
  ## 
  let valid = call_606317.validator(path, query, header, formData, body)
  let scheme = call_606317.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606317.url(scheme.get, call_606317.host, call_606317.base,
                         call_606317.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606317, url, valid)

proc call*(call_606318: Call_DescribeStreamSummary_606305; body: JsonNode): Recallable =
  ## describeStreamSummary
  ## <p>Provides a summarized description of the specified Kinesis data stream without the shard list.</p> <p>The information returned includes the stream name, Amazon Resource Name (ARN), status, record retention period, approximate creation time, monitoring, encryption details, and open shard count. </p>
  ##   body: JObject (required)
  var body_606319 = newJObject()
  if body != nil:
    body_606319 = body
  result = call_606318.call(nil, nil, nil, nil, body_606319)

var describeStreamSummary* = Call_DescribeStreamSummary_606305(
    name: "describeStreamSummary", meth: HttpMethod.HttpPost,
    host: "kinesis.amazonaws.com",
    route: "/#X-Amz-Target=Kinesis_20131202.DescribeStreamSummary",
    validator: validate_DescribeStreamSummary_606306, base: "/",
    url: url_DescribeStreamSummary_606307, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableEnhancedMonitoring_606320 = ref object of OpenApiRestCall_605589
proc url_DisableEnhancedMonitoring_606322(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisableEnhancedMonitoring_606321(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Disables enhanced monitoring.
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
  var valid_606323 = header.getOrDefault("X-Amz-Target")
  valid_606323 = validateParameter(valid_606323, JString, required = true, default = newJString(
      "Kinesis_20131202.DisableEnhancedMonitoring"))
  if valid_606323 != nil:
    section.add "X-Amz-Target", valid_606323
  var valid_606324 = header.getOrDefault("X-Amz-Signature")
  valid_606324 = validateParameter(valid_606324, JString, required = false,
                                 default = nil)
  if valid_606324 != nil:
    section.add "X-Amz-Signature", valid_606324
  var valid_606325 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606325 = validateParameter(valid_606325, JString, required = false,
                                 default = nil)
  if valid_606325 != nil:
    section.add "X-Amz-Content-Sha256", valid_606325
  var valid_606326 = header.getOrDefault("X-Amz-Date")
  valid_606326 = validateParameter(valid_606326, JString, required = false,
                                 default = nil)
  if valid_606326 != nil:
    section.add "X-Amz-Date", valid_606326
  var valid_606327 = header.getOrDefault("X-Amz-Credential")
  valid_606327 = validateParameter(valid_606327, JString, required = false,
                                 default = nil)
  if valid_606327 != nil:
    section.add "X-Amz-Credential", valid_606327
  var valid_606328 = header.getOrDefault("X-Amz-Security-Token")
  valid_606328 = validateParameter(valid_606328, JString, required = false,
                                 default = nil)
  if valid_606328 != nil:
    section.add "X-Amz-Security-Token", valid_606328
  var valid_606329 = header.getOrDefault("X-Amz-Algorithm")
  valid_606329 = validateParameter(valid_606329, JString, required = false,
                                 default = nil)
  if valid_606329 != nil:
    section.add "X-Amz-Algorithm", valid_606329
  var valid_606330 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606330 = validateParameter(valid_606330, JString, required = false,
                                 default = nil)
  if valid_606330 != nil:
    section.add "X-Amz-SignedHeaders", valid_606330
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606332: Call_DisableEnhancedMonitoring_606320; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables enhanced monitoring.
  ## 
  let valid = call_606332.validator(path, query, header, formData, body)
  let scheme = call_606332.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606332.url(scheme.get, call_606332.host, call_606332.base,
                         call_606332.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606332, url, valid)

proc call*(call_606333: Call_DisableEnhancedMonitoring_606320; body: JsonNode): Recallable =
  ## disableEnhancedMonitoring
  ## Disables enhanced monitoring.
  ##   body: JObject (required)
  var body_606334 = newJObject()
  if body != nil:
    body_606334 = body
  result = call_606333.call(nil, nil, nil, nil, body_606334)

var disableEnhancedMonitoring* = Call_DisableEnhancedMonitoring_606320(
    name: "disableEnhancedMonitoring", meth: HttpMethod.HttpPost,
    host: "kinesis.amazonaws.com",
    route: "/#X-Amz-Target=Kinesis_20131202.DisableEnhancedMonitoring",
    validator: validate_DisableEnhancedMonitoring_606321, base: "/",
    url: url_DisableEnhancedMonitoring_606322,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableEnhancedMonitoring_606335 = ref object of OpenApiRestCall_605589
proc url_EnableEnhancedMonitoring_606337(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_EnableEnhancedMonitoring_606336(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Enables enhanced Kinesis data stream monitoring for shard-level metrics.
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
  var valid_606338 = header.getOrDefault("X-Amz-Target")
  valid_606338 = validateParameter(valid_606338, JString, required = true, default = newJString(
      "Kinesis_20131202.EnableEnhancedMonitoring"))
  if valid_606338 != nil:
    section.add "X-Amz-Target", valid_606338
  var valid_606339 = header.getOrDefault("X-Amz-Signature")
  valid_606339 = validateParameter(valid_606339, JString, required = false,
                                 default = nil)
  if valid_606339 != nil:
    section.add "X-Amz-Signature", valid_606339
  var valid_606340 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606340 = validateParameter(valid_606340, JString, required = false,
                                 default = nil)
  if valid_606340 != nil:
    section.add "X-Amz-Content-Sha256", valid_606340
  var valid_606341 = header.getOrDefault("X-Amz-Date")
  valid_606341 = validateParameter(valid_606341, JString, required = false,
                                 default = nil)
  if valid_606341 != nil:
    section.add "X-Amz-Date", valid_606341
  var valid_606342 = header.getOrDefault("X-Amz-Credential")
  valid_606342 = validateParameter(valid_606342, JString, required = false,
                                 default = nil)
  if valid_606342 != nil:
    section.add "X-Amz-Credential", valid_606342
  var valid_606343 = header.getOrDefault("X-Amz-Security-Token")
  valid_606343 = validateParameter(valid_606343, JString, required = false,
                                 default = nil)
  if valid_606343 != nil:
    section.add "X-Amz-Security-Token", valid_606343
  var valid_606344 = header.getOrDefault("X-Amz-Algorithm")
  valid_606344 = validateParameter(valid_606344, JString, required = false,
                                 default = nil)
  if valid_606344 != nil:
    section.add "X-Amz-Algorithm", valid_606344
  var valid_606345 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606345 = validateParameter(valid_606345, JString, required = false,
                                 default = nil)
  if valid_606345 != nil:
    section.add "X-Amz-SignedHeaders", valid_606345
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606347: Call_EnableEnhancedMonitoring_606335; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables enhanced Kinesis data stream monitoring for shard-level metrics.
  ## 
  let valid = call_606347.validator(path, query, header, formData, body)
  let scheme = call_606347.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606347.url(scheme.get, call_606347.host, call_606347.base,
                         call_606347.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606347, url, valid)

proc call*(call_606348: Call_EnableEnhancedMonitoring_606335; body: JsonNode): Recallable =
  ## enableEnhancedMonitoring
  ## Enables enhanced Kinesis data stream monitoring for shard-level metrics.
  ##   body: JObject (required)
  var body_606349 = newJObject()
  if body != nil:
    body_606349 = body
  result = call_606348.call(nil, nil, nil, nil, body_606349)

var enableEnhancedMonitoring* = Call_EnableEnhancedMonitoring_606335(
    name: "enableEnhancedMonitoring", meth: HttpMethod.HttpPost,
    host: "kinesis.amazonaws.com",
    route: "/#X-Amz-Target=Kinesis_20131202.EnableEnhancedMonitoring",
    validator: validate_EnableEnhancedMonitoring_606336, base: "/",
    url: url_EnableEnhancedMonitoring_606337, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRecords_606350 = ref object of OpenApiRestCall_605589
proc url_GetRecords_606352(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRecords_606351(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets data records from a Kinesis data stream's shard.</p> <p>Specify a shard iterator using the <code>ShardIterator</code> parameter. The shard iterator specifies the position in the shard from which you want to start reading data records sequentially. If there are no records available in the portion of the shard that the iterator points to, <a>GetRecords</a> returns an empty list. It might take multiple calls to get to a portion of the shard that contains records.</p> <p>You can scale by provisioning multiple shards per stream while considering service limits (for more information, see <a href="http://docs.aws.amazon.com/kinesis/latest/dev/service-sizes-and-limits.html">Amazon Kinesis Data Streams Limits</a> in the <i>Amazon Kinesis Data Streams Developer Guide</i>). Your application should have one thread per shard, each reading continuously from its stream. To read from a stream continually, call <a>GetRecords</a> in a loop. Use <a>GetShardIterator</a> to get the shard iterator to specify in the first <a>GetRecords</a> call. <a>GetRecords</a> returns a new shard iterator in <code>NextShardIterator</code>. Specify the shard iterator returned in <code>NextShardIterator</code> in subsequent calls to <a>GetRecords</a>. If the shard has been closed, the shard iterator can't return more data and <a>GetRecords</a> returns <code>null</code> in <code>NextShardIterator</code>. You can terminate the loop when the shard is closed, or when the shard iterator reaches the record with the sequence number or other attribute that marks it as the last record to process.</p> <p>Each data record can be up to 1 MiB in size, and each shard can read up to 2 MiB per second. You can ensure that your calls don't exceed the maximum supported size or throughput by using the <code>Limit</code> parameter to specify the maximum number of records that <a>GetRecords</a> can return. Consider your average record size when determining this limit. The maximum number of records that can be returned per call is 10,000.</p> <p>The size of the data returned by <a>GetRecords</a> varies depending on the utilization of the shard. The maximum size of data that <a>GetRecords</a> can return is 10 MiB. If a call returns this amount of data, subsequent calls made within the next 5 seconds throw <code>ProvisionedThroughputExceededException</code>. If there is insufficient provisioned throughput on the stream, subsequent calls made within the next 1 second throw <code>ProvisionedThroughputExceededException</code>. <a>GetRecords</a> doesn't return any data when it throws an exception. For this reason, we recommend that you wait 1 second between calls to <a>GetRecords</a>. However, it's possible that the application will get exceptions for longer than 1 second.</p> <p>To detect whether the application is falling behind in processing, you can use the <code>MillisBehindLatest</code> response attribute. You can also monitor the stream using CloudWatch metrics and other mechanisms (see <a href="http://docs.aws.amazon.com/kinesis/latest/dev/monitoring.html">Monitoring</a> in the <i>Amazon Kinesis Data Streams Developer Guide</i>).</p> <p>Each Amazon Kinesis record includes a value, <code>ApproximateArrivalTimestamp</code>, that is set when a stream successfully receives and stores a record. This is commonly referred to as a server-side time stamp, whereas a client-side time stamp is set when a data producer creates or sends the record to a stream (a data producer is any data source putting data records into a stream, for example with <a>PutRecords</a>). The time stamp has millisecond precision. There are no guarantees about the time stamp accuracy, or that the time stamp is always increasing. For example, records in a shard or across a stream might have time stamps that are out of order.</p> <p>This operation has a limit of five transactions per second per account.</p>
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
  var valid_606353 = header.getOrDefault("X-Amz-Target")
  valid_606353 = validateParameter(valid_606353, JString, required = true, default = newJString(
      "Kinesis_20131202.GetRecords"))
  if valid_606353 != nil:
    section.add "X-Amz-Target", valid_606353
  var valid_606354 = header.getOrDefault("X-Amz-Signature")
  valid_606354 = validateParameter(valid_606354, JString, required = false,
                                 default = nil)
  if valid_606354 != nil:
    section.add "X-Amz-Signature", valid_606354
  var valid_606355 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606355 = validateParameter(valid_606355, JString, required = false,
                                 default = nil)
  if valid_606355 != nil:
    section.add "X-Amz-Content-Sha256", valid_606355
  var valid_606356 = header.getOrDefault("X-Amz-Date")
  valid_606356 = validateParameter(valid_606356, JString, required = false,
                                 default = nil)
  if valid_606356 != nil:
    section.add "X-Amz-Date", valid_606356
  var valid_606357 = header.getOrDefault("X-Amz-Credential")
  valid_606357 = validateParameter(valid_606357, JString, required = false,
                                 default = nil)
  if valid_606357 != nil:
    section.add "X-Amz-Credential", valid_606357
  var valid_606358 = header.getOrDefault("X-Amz-Security-Token")
  valid_606358 = validateParameter(valid_606358, JString, required = false,
                                 default = nil)
  if valid_606358 != nil:
    section.add "X-Amz-Security-Token", valid_606358
  var valid_606359 = header.getOrDefault("X-Amz-Algorithm")
  valid_606359 = validateParameter(valid_606359, JString, required = false,
                                 default = nil)
  if valid_606359 != nil:
    section.add "X-Amz-Algorithm", valid_606359
  var valid_606360 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606360 = validateParameter(valid_606360, JString, required = false,
                                 default = nil)
  if valid_606360 != nil:
    section.add "X-Amz-SignedHeaders", valid_606360
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606362: Call_GetRecords_606350; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets data records from a Kinesis data stream's shard.</p> <p>Specify a shard iterator using the <code>ShardIterator</code> parameter. The shard iterator specifies the position in the shard from which you want to start reading data records sequentially. If there are no records available in the portion of the shard that the iterator points to, <a>GetRecords</a> returns an empty list. It might take multiple calls to get to a portion of the shard that contains records.</p> <p>You can scale by provisioning multiple shards per stream while considering service limits (for more information, see <a href="http://docs.aws.amazon.com/kinesis/latest/dev/service-sizes-and-limits.html">Amazon Kinesis Data Streams Limits</a> in the <i>Amazon Kinesis Data Streams Developer Guide</i>). Your application should have one thread per shard, each reading continuously from its stream. To read from a stream continually, call <a>GetRecords</a> in a loop. Use <a>GetShardIterator</a> to get the shard iterator to specify in the first <a>GetRecords</a> call. <a>GetRecords</a> returns a new shard iterator in <code>NextShardIterator</code>. Specify the shard iterator returned in <code>NextShardIterator</code> in subsequent calls to <a>GetRecords</a>. If the shard has been closed, the shard iterator can't return more data and <a>GetRecords</a> returns <code>null</code> in <code>NextShardIterator</code>. You can terminate the loop when the shard is closed, or when the shard iterator reaches the record with the sequence number or other attribute that marks it as the last record to process.</p> <p>Each data record can be up to 1 MiB in size, and each shard can read up to 2 MiB per second. You can ensure that your calls don't exceed the maximum supported size or throughput by using the <code>Limit</code> parameter to specify the maximum number of records that <a>GetRecords</a> can return. Consider your average record size when determining this limit. The maximum number of records that can be returned per call is 10,000.</p> <p>The size of the data returned by <a>GetRecords</a> varies depending on the utilization of the shard. The maximum size of data that <a>GetRecords</a> can return is 10 MiB. If a call returns this amount of data, subsequent calls made within the next 5 seconds throw <code>ProvisionedThroughputExceededException</code>. If there is insufficient provisioned throughput on the stream, subsequent calls made within the next 1 second throw <code>ProvisionedThroughputExceededException</code>. <a>GetRecords</a> doesn't return any data when it throws an exception. For this reason, we recommend that you wait 1 second between calls to <a>GetRecords</a>. However, it's possible that the application will get exceptions for longer than 1 second.</p> <p>To detect whether the application is falling behind in processing, you can use the <code>MillisBehindLatest</code> response attribute. You can also monitor the stream using CloudWatch metrics and other mechanisms (see <a href="http://docs.aws.amazon.com/kinesis/latest/dev/monitoring.html">Monitoring</a> in the <i>Amazon Kinesis Data Streams Developer Guide</i>).</p> <p>Each Amazon Kinesis record includes a value, <code>ApproximateArrivalTimestamp</code>, that is set when a stream successfully receives and stores a record. This is commonly referred to as a server-side time stamp, whereas a client-side time stamp is set when a data producer creates or sends the record to a stream (a data producer is any data source putting data records into a stream, for example with <a>PutRecords</a>). The time stamp has millisecond precision. There are no guarantees about the time stamp accuracy, or that the time stamp is always increasing. For example, records in a shard or across a stream might have time stamps that are out of order.</p> <p>This operation has a limit of five transactions per second per account.</p>
  ## 
  let valid = call_606362.validator(path, query, header, formData, body)
  let scheme = call_606362.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606362.url(scheme.get, call_606362.host, call_606362.base,
                         call_606362.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606362, url, valid)

proc call*(call_606363: Call_GetRecords_606350; body: JsonNode): Recallable =
  ## getRecords
  ## <p>Gets data records from a Kinesis data stream's shard.</p> <p>Specify a shard iterator using the <code>ShardIterator</code> parameter. The shard iterator specifies the position in the shard from which you want to start reading data records sequentially. If there are no records available in the portion of the shard that the iterator points to, <a>GetRecords</a> returns an empty list. It might take multiple calls to get to a portion of the shard that contains records.</p> <p>You can scale by provisioning multiple shards per stream while considering service limits (for more information, see <a href="http://docs.aws.amazon.com/kinesis/latest/dev/service-sizes-and-limits.html">Amazon Kinesis Data Streams Limits</a> in the <i>Amazon Kinesis Data Streams Developer Guide</i>). Your application should have one thread per shard, each reading continuously from its stream. To read from a stream continually, call <a>GetRecords</a> in a loop. Use <a>GetShardIterator</a> to get the shard iterator to specify in the first <a>GetRecords</a> call. <a>GetRecords</a> returns a new shard iterator in <code>NextShardIterator</code>. Specify the shard iterator returned in <code>NextShardIterator</code> in subsequent calls to <a>GetRecords</a>. If the shard has been closed, the shard iterator can't return more data and <a>GetRecords</a> returns <code>null</code> in <code>NextShardIterator</code>. You can terminate the loop when the shard is closed, or when the shard iterator reaches the record with the sequence number or other attribute that marks it as the last record to process.</p> <p>Each data record can be up to 1 MiB in size, and each shard can read up to 2 MiB per second. You can ensure that your calls don't exceed the maximum supported size or throughput by using the <code>Limit</code> parameter to specify the maximum number of records that <a>GetRecords</a> can return. Consider your average record size when determining this limit. The maximum number of records that can be returned per call is 10,000.</p> <p>The size of the data returned by <a>GetRecords</a> varies depending on the utilization of the shard. The maximum size of data that <a>GetRecords</a> can return is 10 MiB. If a call returns this amount of data, subsequent calls made within the next 5 seconds throw <code>ProvisionedThroughputExceededException</code>. If there is insufficient provisioned throughput on the stream, subsequent calls made within the next 1 second throw <code>ProvisionedThroughputExceededException</code>. <a>GetRecords</a> doesn't return any data when it throws an exception. For this reason, we recommend that you wait 1 second between calls to <a>GetRecords</a>. However, it's possible that the application will get exceptions for longer than 1 second.</p> <p>To detect whether the application is falling behind in processing, you can use the <code>MillisBehindLatest</code> response attribute. You can also monitor the stream using CloudWatch metrics and other mechanisms (see <a href="http://docs.aws.amazon.com/kinesis/latest/dev/monitoring.html">Monitoring</a> in the <i>Amazon Kinesis Data Streams Developer Guide</i>).</p> <p>Each Amazon Kinesis record includes a value, <code>ApproximateArrivalTimestamp</code>, that is set when a stream successfully receives and stores a record. This is commonly referred to as a server-side time stamp, whereas a client-side time stamp is set when a data producer creates or sends the record to a stream (a data producer is any data source putting data records into a stream, for example with <a>PutRecords</a>). The time stamp has millisecond precision. There are no guarantees about the time stamp accuracy, or that the time stamp is always increasing. For example, records in a shard or across a stream might have time stamps that are out of order.</p> <p>This operation has a limit of five transactions per second per account.</p>
  ##   body: JObject (required)
  var body_606364 = newJObject()
  if body != nil:
    body_606364 = body
  result = call_606363.call(nil, nil, nil, nil, body_606364)

var getRecords* = Call_GetRecords_606350(name: "getRecords",
                                      meth: HttpMethod.HttpPost,
                                      host: "kinesis.amazonaws.com", route: "/#X-Amz-Target=Kinesis_20131202.GetRecords",
                                      validator: validate_GetRecords_606351,
                                      base: "/", url: url_GetRecords_606352,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetShardIterator_606365 = ref object of OpenApiRestCall_605589
proc url_GetShardIterator_606367(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetShardIterator_606366(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Gets an Amazon Kinesis shard iterator. A shard iterator expires 5 minutes after it is returned to the requester.</p> <p>A shard iterator specifies the shard position from which to start reading data records sequentially. The position is specified using the sequence number of a data record in a shard. A sequence number is the identifier associated with every record ingested in the stream, and is assigned when a record is put into the stream. Each stream has one or more shards.</p> <p>You must specify the shard iterator type. For example, you can set the <code>ShardIteratorType</code> parameter to read exactly from the position denoted by a specific sequence number by using the <code>AT_SEQUENCE_NUMBER</code> shard iterator type. Alternatively, the parameter can read right after the sequence number by using the <code>AFTER_SEQUENCE_NUMBER</code> shard iterator type, using sequence numbers returned by earlier calls to <a>PutRecord</a>, <a>PutRecords</a>, <a>GetRecords</a>, or <a>DescribeStream</a>. In the request, you can specify the shard iterator type <code>AT_TIMESTAMP</code> to read records from an arbitrary point in time, <code>TRIM_HORIZON</code> to cause <code>ShardIterator</code> to point to the last untrimmed record in the shard in the system (the oldest data record in the shard), or <code>LATEST</code> so that you always read the most recent data in the shard. </p> <p>When you read repeatedly from a stream, use a <a>GetShardIterator</a> request to get the first shard iterator for use in your first <a>GetRecords</a> request and for subsequent reads use the shard iterator returned by the <a>GetRecords</a> request in <code>NextShardIterator</code>. A new shard iterator is returned by every <a>GetRecords</a> request in <code>NextShardIterator</code>, which you use in the <code>ShardIterator</code> parameter of the next <a>GetRecords</a> request. </p> <p>If a <a>GetShardIterator</a> request is made too often, you receive a <code>ProvisionedThroughputExceededException</code>. For more information about throughput limits, see <a>GetRecords</a>, and <a href="http://docs.aws.amazon.com/kinesis/latest/dev/service-sizes-and-limits.html">Streams Limits</a> in the <i>Amazon Kinesis Data Streams Developer Guide</i>.</p> <p>If the shard is closed, <a>GetShardIterator</a> returns a valid iterator for the last sequence number of the shard. A shard can be closed as a result of using <a>SplitShard</a> or <a>MergeShards</a>.</p> <p> <a>GetShardIterator</a> has a limit of five transactions per second per account per open shard.</p>
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
  var valid_606368 = header.getOrDefault("X-Amz-Target")
  valid_606368 = validateParameter(valid_606368, JString, required = true, default = newJString(
      "Kinesis_20131202.GetShardIterator"))
  if valid_606368 != nil:
    section.add "X-Amz-Target", valid_606368
  var valid_606369 = header.getOrDefault("X-Amz-Signature")
  valid_606369 = validateParameter(valid_606369, JString, required = false,
                                 default = nil)
  if valid_606369 != nil:
    section.add "X-Amz-Signature", valid_606369
  var valid_606370 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606370 = validateParameter(valid_606370, JString, required = false,
                                 default = nil)
  if valid_606370 != nil:
    section.add "X-Amz-Content-Sha256", valid_606370
  var valid_606371 = header.getOrDefault("X-Amz-Date")
  valid_606371 = validateParameter(valid_606371, JString, required = false,
                                 default = nil)
  if valid_606371 != nil:
    section.add "X-Amz-Date", valid_606371
  var valid_606372 = header.getOrDefault("X-Amz-Credential")
  valid_606372 = validateParameter(valid_606372, JString, required = false,
                                 default = nil)
  if valid_606372 != nil:
    section.add "X-Amz-Credential", valid_606372
  var valid_606373 = header.getOrDefault("X-Amz-Security-Token")
  valid_606373 = validateParameter(valid_606373, JString, required = false,
                                 default = nil)
  if valid_606373 != nil:
    section.add "X-Amz-Security-Token", valid_606373
  var valid_606374 = header.getOrDefault("X-Amz-Algorithm")
  valid_606374 = validateParameter(valid_606374, JString, required = false,
                                 default = nil)
  if valid_606374 != nil:
    section.add "X-Amz-Algorithm", valid_606374
  var valid_606375 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606375 = validateParameter(valid_606375, JString, required = false,
                                 default = nil)
  if valid_606375 != nil:
    section.add "X-Amz-SignedHeaders", valid_606375
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606377: Call_GetShardIterator_606365; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets an Amazon Kinesis shard iterator. A shard iterator expires 5 minutes after it is returned to the requester.</p> <p>A shard iterator specifies the shard position from which to start reading data records sequentially. The position is specified using the sequence number of a data record in a shard. A sequence number is the identifier associated with every record ingested in the stream, and is assigned when a record is put into the stream. Each stream has one or more shards.</p> <p>You must specify the shard iterator type. For example, you can set the <code>ShardIteratorType</code> parameter to read exactly from the position denoted by a specific sequence number by using the <code>AT_SEQUENCE_NUMBER</code> shard iterator type. Alternatively, the parameter can read right after the sequence number by using the <code>AFTER_SEQUENCE_NUMBER</code> shard iterator type, using sequence numbers returned by earlier calls to <a>PutRecord</a>, <a>PutRecords</a>, <a>GetRecords</a>, or <a>DescribeStream</a>. In the request, you can specify the shard iterator type <code>AT_TIMESTAMP</code> to read records from an arbitrary point in time, <code>TRIM_HORIZON</code> to cause <code>ShardIterator</code> to point to the last untrimmed record in the shard in the system (the oldest data record in the shard), or <code>LATEST</code> so that you always read the most recent data in the shard. </p> <p>When you read repeatedly from a stream, use a <a>GetShardIterator</a> request to get the first shard iterator for use in your first <a>GetRecords</a> request and for subsequent reads use the shard iterator returned by the <a>GetRecords</a> request in <code>NextShardIterator</code>. A new shard iterator is returned by every <a>GetRecords</a> request in <code>NextShardIterator</code>, which you use in the <code>ShardIterator</code> parameter of the next <a>GetRecords</a> request. </p> <p>If a <a>GetShardIterator</a> request is made too often, you receive a <code>ProvisionedThroughputExceededException</code>. For more information about throughput limits, see <a>GetRecords</a>, and <a href="http://docs.aws.amazon.com/kinesis/latest/dev/service-sizes-and-limits.html">Streams Limits</a> in the <i>Amazon Kinesis Data Streams Developer Guide</i>.</p> <p>If the shard is closed, <a>GetShardIterator</a> returns a valid iterator for the last sequence number of the shard. A shard can be closed as a result of using <a>SplitShard</a> or <a>MergeShards</a>.</p> <p> <a>GetShardIterator</a> has a limit of five transactions per second per account per open shard.</p>
  ## 
  let valid = call_606377.validator(path, query, header, formData, body)
  let scheme = call_606377.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606377.url(scheme.get, call_606377.host, call_606377.base,
                         call_606377.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606377, url, valid)

proc call*(call_606378: Call_GetShardIterator_606365; body: JsonNode): Recallable =
  ## getShardIterator
  ## <p>Gets an Amazon Kinesis shard iterator. A shard iterator expires 5 minutes after it is returned to the requester.</p> <p>A shard iterator specifies the shard position from which to start reading data records sequentially. The position is specified using the sequence number of a data record in a shard. A sequence number is the identifier associated with every record ingested in the stream, and is assigned when a record is put into the stream. Each stream has one or more shards.</p> <p>You must specify the shard iterator type. For example, you can set the <code>ShardIteratorType</code> parameter to read exactly from the position denoted by a specific sequence number by using the <code>AT_SEQUENCE_NUMBER</code> shard iterator type. Alternatively, the parameter can read right after the sequence number by using the <code>AFTER_SEQUENCE_NUMBER</code> shard iterator type, using sequence numbers returned by earlier calls to <a>PutRecord</a>, <a>PutRecords</a>, <a>GetRecords</a>, or <a>DescribeStream</a>. In the request, you can specify the shard iterator type <code>AT_TIMESTAMP</code> to read records from an arbitrary point in time, <code>TRIM_HORIZON</code> to cause <code>ShardIterator</code> to point to the last untrimmed record in the shard in the system (the oldest data record in the shard), or <code>LATEST</code> so that you always read the most recent data in the shard. </p> <p>When you read repeatedly from a stream, use a <a>GetShardIterator</a> request to get the first shard iterator for use in your first <a>GetRecords</a> request and for subsequent reads use the shard iterator returned by the <a>GetRecords</a> request in <code>NextShardIterator</code>. A new shard iterator is returned by every <a>GetRecords</a> request in <code>NextShardIterator</code>, which you use in the <code>ShardIterator</code> parameter of the next <a>GetRecords</a> request. </p> <p>If a <a>GetShardIterator</a> request is made too often, you receive a <code>ProvisionedThroughputExceededException</code>. For more information about throughput limits, see <a>GetRecords</a>, and <a href="http://docs.aws.amazon.com/kinesis/latest/dev/service-sizes-and-limits.html">Streams Limits</a> in the <i>Amazon Kinesis Data Streams Developer Guide</i>.</p> <p>If the shard is closed, <a>GetShardIterator</a> returns a valid iterator for the last sequence number of the shard. A shard can be closed as a result of using <a>SplitShard</a> or <a>MergeShards</a>.</p> <p> <a>GetShardIterator</a> has a limit of five transactions per second per account per open shard.</p>
  ##   body: JObject (required)
  var body_606379 = newJObject()
  if body != nil:
    body_606379 = body
  result = call_606378.call(nil, nil, nil, nil, body_606379)

var getShardIterator* = Call_GetShardIterator_606365(name: "getShardIterator",
    meth: HttpMethod.HttpPost, host: "kinesis.amazonaws.com",
    route: "/#X-Amz-Target=Kinesis_20131202.GetShardIterator",
    validator: validate_GetShardIterator_606366, base: "/",
    url: url_GetShardIterator_606367, schemes: {Scheme.Https, Scheme.Http})
type
  Call_IncreaseStreamRetentionPeriod_606380 = ref object of OpenApiRestCall_605589
proc url_IncreaseStreamRetentionPeriod_606382(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_IncreaseStreamRetentionPeriod_606381(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Increases the Kinesis data stream's retention period, which is the length of time data records are accessible after they are added to the stream. The maximum value of a stream's retention period is 168 hours (7 days).</p> <p>If you choose a longer stream retention period, this operation increases the time period during which records that have not yet expired are accessible. However, it does not make previous, expired data (older than the stream's previous retention period) accessible after the operation has been called. For example, if a stream's retention period is set to 24 hours and is increased to 168 hours, any data that is older than 24 hours remains inaccessible to consumer applications.</p>
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
  var valid_606383 = header.getOrDefault("X-Amz-Target")
  valid_606383 = validateParameter(valid_606383, JString, required = true, default = newJString(
      "Kinesis_20131202.IncreaseStreamRetentionPeriod"))
  if valid_606383 != nil:
    section.add "X-Amz-Target", valid_606383
  var valid_606384 = header.getOrDefault("X-Amz-Signature")
  valid_606384 = validateParameter(valid_606384, JString, required = false,
                                 default = nil)
  if valid_606384 != nil:
    section.add "X-Amz-Signature", valid_606384
  var valid_606385 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606385 = validateParameter(valid_606385, JString, required = false,
                                 default = nil)
  if valid_606385 != nil:
    section.add "X-Amz-Content-Sha256", valid_606385
  var valid_606386 = header.getOrDefault("X-Amz-Date")
  valid_606386 = validateParameter(valid_606386, JString, required = false,
                                 default = nil)
  if valid_606386 != nil:
    section.add "X-Amz-Date", valid_606386
  var valid_606387 = header.getOrDefault("X-Amz-Credential")
  valid_606387 = validateParameter(valid_606387, JString, required = false,
                                 default = nil)
  if valid_606387 != nil:
    section.add "X-Amz-Credential", valid_606387
  var valid_606388 = header.getOrDefault("X-Amz-Security-Token")
  valid_606388 = validateParameter(valid_606388, JString, required = false,
                                 default = nil)
  if valid_606388 != nil:
    section.add "X-Amz-Security-Token", valid_606388
  var valid_606389 = header.getOrDefault("X-Amz-Algorithm")
  valid_606389 = validateParameter(valid_606389, JString, required = false,
                                 default = nil)
  if valid_606389 != nil:
    section.add "X-Amz-Algorithm", valid_606389
  var valid_606390 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606390 = validateParameter(valid_606390, JString, required = false,
                                 default = nil)
  if valid_606390 != nil:
    section.add "X-Amz-SignedHeaders", valid_606390
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606392: Call_IncreaseStreamRetentionPeriod_606380; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Increases the Kinesis data stream's retention period, which is the length of time data records are accessible after they are added to the stream. The maximum value of a stream's retention period is 168 hours (7 days).</p> <p>If you choose a longer stream retention period, this operation increases the time period during which records that have not yet expired are accessible. However, it does not make previous, expired data (older than the stream's previous retention period) accessible after the operation has been called. For example, if a stream's retention period is set to 24 hours and is increased to 168 hours, any data that is older than 24 hours remains inaccessible to consumer applications.</p>
  ## 
  let valid = call_606392.validator(path, query, header, formData, body)
  let scheme = call_606392.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606392.url(scheme.get, call_606392.host, call_606392.base,
                         call_606392.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606392, url, valid)

proc call*(call_606393: Call_IncreaseStreamRetentionPeriod_606380; body: JsonNode): Recallable =
  ## increaseStreamRetentionPeriod
  ## <p>Increases the Kinesis data stream's retention period, which is the length of time data records are accessible after they are added to the stream. The maximum value of a stream's retention period is 168 hours (7 days).</p> <p>If you choose a longer stream retention period, this operation increases the time period during which records that have not yet expired are accessible. However, it does not make previous, expired data (older than the stream's previous retention period) accessible after the operation has been called. For example, if a stream's retention period is set to 24 hours and is increased to 168 hours, any data that is older than 24 hours remains inaccessible to consumer applications.</p>
  ##   body: JObject (required)
  var body_606394 = newJObject()
  if body != nil:
    body_606394 = body
  result = call_606393.call(nil, nil, nil, nil, body_606394)

var increaseStreamRetentionPeriod* = Call_IncreaseStreamRetentionPeriod_606380(
    name: "increaseStreamRetentionPeriod", meth: HttpMethod.HttpPost,
    host: "kinesis.amazonaws.com",
    route: "/#X-Amz-Target=Kinesis_20131202.IncreaseStreamRetentionPeriod",
    validator: validate_IncreaseStreamRetentionPeriod_606381, base: "/",
    url: url_IncreaseStreamRetentionPeriod_606382,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListShards_606395 = ref object of OpenApiRestCall_605589
proc url_ListShards_606397(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListShards_606396(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists the shards in a stream and provides information about each shard. This operation has a limit of 100 transactions per second per data stream.</p> <important> <p>This API is a new operation that is used by the Amazon Kinesis Client Library (KCL). If you have a fine-grained IAM policy that only allows specific operations, you must update your policy to allow calls to this API. For more information, see <a href="https://docs.aws.amazon.com/streams/latest/dev/controlling-access.html">Controlling Access to Amazon Kinesis Data Streams Resources Using IAM</a>.</p> </important>
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
  var valid_606398 = header.getOrDefault("X-Amz-Target")
  valid_606398 = validateParameter(valid_606398, JString, required = true, default = newJString(
      "Kinesis_20131202.ListShards"))
  if valid_606398 != nil:
    section.add "X-Amz-Target", valid_606398
  var valid_606399 = header.getOrDefault("X-Amz-Signature")
  valid_606399 = validateParameter(valid_606399, JString, required = false,
                                 default = nil)
  if valid_606399 != nil:
    section.add "X-Amz-Signature", valid_606399
  var valid_606400 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606400 = validateParameter(valid_606400, JString, required = false,
                                 default = nil)
  if valid_606400 != nil:
    section.add "X-Amz-Content-Sha256", valid_606400
  var valid_606401 = header.getOrDefault("X-Amz-Date")
  valid_606401 = validateParameter(valid_606401, JString, required = false,
                                 default = nil)
  if valid_606401 != nil:
    section.add "X-Amz-Date", valid_606401
  var valid_606402 = header.getOrDefault("X-Amz-Credential")
  valid_606402 = validateParameter(valid_606402, JString, required = false,
                                 default = nil)
  if valid_606402 != nil:
    section.add "X-Amz-Credential", valid_606402
  var valid_606403 = header.getOrDefault("X-Amz-Security-Token")
  valid_606403 = validateParameter(valid_606403, JString, required = false,
                                 default = nil)
  if valid_606403 != nil:
    section.add "X-Amz-Security-Token", valid_606403
  var valid_606404 = header.getOrDefault("X-Amz-Algorithm")
  valid_606404 = validateParameter(valid_606404, JString, required = false,
                                 default = nil)
  if valid_606404 != nil:
    section.add "X-Amz-Algorithm", valid_606404
  var valid_606405 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606405 = validateParameter(valid_606405, JString, required = false,
                                 default = nil)
  if valid_606405 != nil:
    section.add "X-Amz-SignedHeaders", valid_606405
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606407: Call_ListShards_606395; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the shards in a stream and provides information about each shard. This operation has a limit of 100 transactions per second per data stream.</p> <important> <p>This API is a new operation that is used by the Amazon Kinesis Client Library (KCL). If you have a fine-grained IAM policy that only allows specific operations, you must update your policy to allow calls to this API. For more information, see <a href="https://docs.aws.amazon.com/streams/latest/dev/controlling-access.html">Controlling Access to Amazon Kinesis Data Streams Resources Using IAM</a>.</p> </important>
  ## 
  let valid = call_606407.validator(path, query, header, formData, body)
  let scheme = call_606407.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606407.url(scheme.get, call_606407.host, call_606407.base,
                         call_606407.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606407, url, valid)

proc call*(call_606408: Call_ListShards_606395; body: JsonNode): Recallable =
  ## listShards
  ## <p>Lists the shards in a stream and provides information about each shard. This operation has a limit of 100 transactions per second per data stream.</p> <important> <p>This API is a new operation that is used by the Amazon Kinesis Client Library (KCL). If you have a fine-grained IAM policy that only allows specific operations, you must update your policy to allow calls to this API. For more information, see <a href="https://docs.aws.amazon.com/streams/latest/dev/controlling-access.html">Controlling Access to Amazon Kinesis Data Streams Resources Using IAM</a>.</p> </important>
  ##   body: JObject (required)
  var body_606409 = newJObject()
  if body != nil:
    body_606409 = body
  result = call_606408.call(nil, nil, nil, nil, body_606409)

var listShards* = Call_ListShards_606395(name: "listShards",
                                      meth: HttpMethod.HttpPost,
                                      host: "kinesis.amazonaws.com", route: "/#X-Amz-Target=Kinesis_20131202.ListShards",
                                      validator: validate_ListShards_606396,
                                      base: "/", url: url_ListShards_606397,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListStreamConsumers_606410 = ref object of OpenApiRestCall_605589
proc url_ListStreamConsumers_606412(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListStreamConsumers_606411(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Lists the consumers registered to receive data from a stream using enhanced fan-out, and provides information about each consumer.</p> <p>This operation has a limit of 10 transactions per second per account.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_606413 = query.getOrDefault("MaxResults")
  valid_606413 = validateParameter(valid_606413, JString, required = false,
                                 default = nil)
  if valid_606413 != nil:
    section.add "MaxResults", valid_606413
  var valid_606414 = query.getOrDefault("NextToken")
  valid_606414 = validateParameter(valid_606414, JString, required = false,
                                 default = nil)
  if valid_606414 != nil:
    section.add "NextToken", valid_606414
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
  var valid_606415 = header.getOrDefault("X-Amz-Target")
  valid_606415 = validateParameter(valid_606415, JString, required = true, default = newJString(
      "Kinesis_20131202.ListStreamConsumers"))
  if valid_606415 != nil:
    section.add "X-Amz-Target", valid_606415
  var valid_606416 = header.getOrDefault("X-Amz-Signature")
  valid_606416 = validateParameter(valid_606416, JString, required = false,
                                 default = nil)
  if valid_606416 != nil:
    section.add "X-Amz-Signature", valid_606416
  var valid_606417 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606417 = validateParameter(valid_606417, JString, required = false,
                                 default = nil)
  if valid_606417 != nil:
    section.add "X-Amz-Content-Sha256", valid_606417
  var valid_606418 = header.getOrDefault("X-Amz-Date")
  valid_606418 = validateParameter(valid_606418, JString, required = false,
                                 default = nil)
  if valid_606418 != nil:
    section.add "X-Amz-Date", valid_606418
  var valid_606419 = header.getOrDefault("X-Amz-Credential")
  valid_606419 = validateParameter(valid_606419, JString, required = false,
                                 default = nil)
  if valid_606419 != nil:
    section.add "X-Amz-Credential", valid_606419
  var valid_606420 = header.getOrDefault("X-Amz-Security-Token")
  valid_606420 = validateParameter(valid_606420, JString, required = false,
                                 default = nil)
  if valid_606420 != nil:
    section.add "X-Amz-Security-Token", valid_606420
  var valid_606421 = header.getOrDefault("X-Amz-Algorithm")
  valid_606421 = validateParameter(valid_606421, JString, required = false,
                                 default = nil)
  if valid_606421 != nil:
    section.add "X-Amz-Algorithm", valid_606421
  var valid_606422 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606422 = validateParameter(valid_606422, JString, required = false,
                                 default = nil)
  if valid_606422 != nil:
    section.add "X-Amz-SignedHeaders", valid_606422
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606424: Call_ListStreamConsumers_606410; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the consumers registered to receive data from a stream using enhanced fan-out, and provides information about each consumer.</p> <p>This operation has a limit of 10 transactions per second per account.</p>
  ## 
  let valid = call_606424.validator(path, query, header, formData, body)
  let scheme = call_606424.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606424.url(scheme.get, call_606424.host, call_606424.base,
                         call_606424.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606424, url, valid)

proc call*(call_606425: Call_ListStreamConsumers_606410; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listStreamConsumers
  ## <p>Lists the consumers registered to receive data from a stream using enhanced fan-out, and provides information about each consumer.</p> <p>This operation has a limit of 10 transactions per second per account.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606426 = newJObject()
  var body_606427 = newJObject()
  add(query_606426, "MaxResults", newJString(MaxResults))
  add(query_606426, "NextToken", newJString(NextToken))
  if body != nil:
    body_606427 = body
  result = call_606425.call(nil, query_606426, nil, nil, body_606427)

var listStreamConsumers* = Call_ListStreamConsumers_606410(
    name: "listStreamConsumers", meth: HttpMethod.HttpPost,
    host: "kinesis.amazonaws.com",
    route: "/#X-Amz-Target=Kinesis_20131202.ListStreamConsumers",
    validator: validate_ListStreamConsumers_606411, base: "/",
    url: url_ListStreamConsumers_606412, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListStreams_606428 = ref object of OpenApiRestCall_605589
proc url_ListStreams_606430(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListStreams_606429(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists your Kinesis data streams.</p> <p>The number of streams may be too large to return from a single call to <code>ListStreams</code>. You can limit the number of returned streams using the <code>Limit</code> parameter. If you do not specify a value for the <code>Limit</code> parameter, Kinesis Data Streams uses the default limit, which is currently 10.</p> <p>You can detect if there are more streams available to list by using the <code>HasMoreStreams</code> flag from the returned output. If there are more streams available, you can request more streams by using the name of the last stream returned by the <code>ListStreams</code> request in the <code>ExclusiveStartStreamName</code> parameter in a subsequent request to <code>ListStreams</code>. The group of stream names returned by the subsequent request is then added to the list. You can continue this process until all the stream names have been collected in the list. </p> <p> <a>ListStreams</a> has a limit of five transactions per second per account.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ExclusiveStartStreamName: JString
  ##                           : Pagination token
  ##   Limit: JString
  ##        : Pagination limit
  section = newJObject()
  var valid_606431 = query.getOrDefault("ExclusiveStartStreamName")
  valid_606431 = validateParameter(valid_606431, JString, required = false,
                                 default = nil)
  if valid_606431 != nil:
    section.add "ExclusiveStartStreamName", valid_606431
  var valid_606432 = query.getOrDefault("Limit")
  valid_606432 = validateParameter(valid_606432, JString, required = false,
                                 default = nil)
  if valid_606432 != nil:
    section.add "Limit", valid_606432
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
  var valid_606433 = header.getOrDefault("X-Amz-Target")
  valid_606433 = validateParameter(valid_606433, JString, required = true, default = newJString(
      "Kinesis_20131202.ListStreams"))
  if valid_606433 != nil:
    section.add "X-Amz-Target", valid_606433
  var valid_606434 = header.getOrDefault("X-Amz-Signature")
  valid_606434 = validateParameter(valid_606434, JString, required = false,
                                 default = nil)
  if valid_606434 != nil:
    section.add "X-Amz-Signature", valid_606434
  var valid_606435 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606435 = validateParameter(valid_606435, JString, required = false,
                                 default = nil)
  if valid_606435 != nil:
    section.add "X-Amz-Content-Sha256", valid_606435
  var valid_606436 = header.getOrDefault("X-Amz-Date")
  valid_606436 = validateParameter(valid_606436, JString, required = false,
                                 default = nil)
  if valid_606436 != nil:
    section.add "X-Amz-Date", valid_606436
  var valid_606437 = header.getOrDefault("X-Amz-Credential")
  valid_606437 = validateParameter(valid_606437, JString, required = false,
                                 default = nil)
  if valid_606437 != nil:
    section.add "X-Amz-Credential", valid_606437
  var valid_606438 = header.getOrDefault("X-Amz-Security-Token")
  valid_606438 = validateParameter(valid_606438, JString, required = false,
                                 default = nil)
  if valid_606438 != nil:
    section.add "X-Amz-Security-Token", valid_606438
  var valid_606439 = header.getOrDefault("X-Amz-Algorithm")
  valid_606439 = validateParameter(valid_606439, JString, required = false,
                                 default = nil)
  if valid_606439 != nil:
    section.add "X-Amz-Algorithm", valid_606439
  var valid_606440 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606440 = validateParameter(valid_606440, JString, required = false,
                                 default = nil)
  if valid_606440 != nil:
    section.add "X-Amz-SignedHeaders", valid_606440
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606442: Call_ListStreams_606428; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists your Kinesis data streams.</p> <p>The number of streams may be too large to return from a single call to <code>ListStreams</code>. You can limit the number of returned streams using the <code>Limit</code> parameter. If you do not specify a value for the <code>Limit</code> parameter, Kinesis Data Streams uses the default limit, which is currently 10.</p> <p>You can detect if there are more streams available to list by using the <code>HasMoreStreams</code> flag from the returned output. If there are more streams available, you can request more streams by using the name of the last stream returned by the <code>ListStreams</code> request in the <code>ExclusiveStartStreamName</code> parameter in a subsequent request to <code>ListStreams</code>. The group of stream names returned by the subsequent request is then added to the list. You can continue this process until all the stream names have been collected in the list. </p> <p> <a>ListStreams</a> has a limit of five transactions per second per account.</p>
  ## 
  let valid = call_606442.validator(path, query, header, formData, body)
  let scheme = call_606442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606442.url(scheme.get, call_606442.host, call_606442.base,
                         call_606442.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606442, url, valid)

proc call*(call_606443: Call_ListStreams_606428; body: JsonNode;
          ExclusiveStartStreamName: string = ""; Limit: string = ""): Recallable =
  ## listStreams
  ## <p>Lists your Kinesis data streams.</p> <p>The number of streams may be too large to return from a single call to <code>ListStreams</code>. You can limit the number of returned streams using the <code>Limit</code> parameter. If you do not specify a value for the <code>Limit</code> parameter, Kinesis Data Streams uses the default limit, which is currently 10.</p> <p>You can detect if there are more streams available to list by using the <code>HasMoreStreams</code> flag from the returned output. If there are more streams available, you can request more streams by using the name of the last stream returned by the <code>ListStreams</code> request in the <code>ExclusiveStartStreamName</code> parameter in a subsequent request to <code>ListStreams</code>. The group of stream names returned by the subsequent request is then added to the list. You can continue this process until all the stream names have been collected in the list. </p> <p> <a>ListStreams</a> has a limit of five transactions per second per account.</p>
  ##   ExclusiveStartStreamName: string
  ##                           : Pagination token
  ##   Limit: string
  ##        : Pagination limit
  ##   body: JObject (required)
  var query_606444 = newJObject()
  var body_606445 = newJObject()
  add(query_606444, "ExclusiveStartStreamName",
      newJString(ExclusiveStartStreamName))
  add(query_606444, "Limit", newJString(Limit))
  if body != nil:
    body_606445 = body
  result = call_606443.call(nil, query_606444, nil, nil, body_606445)

var listStreams* = Call_ListStreams_606428(name: "listStreams",
                                        meth: HttpMethod.HttpPost,
                                        host: "kinesis.amazonaws.com", route: "/#X-Amz-Target=Kinesis_20131202.ListStreams",
                                        validator: validate_ListStreams_606429,
                                        base: "/", url: url_ListStreams_606430,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForStream_606446 = ref object of OpenApiRestCall_605589
proc url_ListTagsForStream_606448(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForStream_606447(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Lists the tags for the specified Kinesis data stream. This operation has a limit of five transactions per second per account.
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
  var valid_606449 = header.getOrDefault("X-Amz-Target")
  valid_606449 = validateParameter(valid_606449, JString, required = true, default = newJString(
      "Kinesis_20131202.ListTagsForStream"))
  if valid_606449 != nil:
    section.add "X-Amz-Target", valid_606449
  var valid_606450 = header.getOrDefault("X-Amz-Signature")
  valid_606450 = validateParameter(valid_606450, JString, required = false,
                                 default = nil)
  if valid_606450 != nil:
    section.add "X-Amz-Signature", valid_606450
  var valid_606451 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606451 = validateParameter(valid_606451, JString, required = false,
                                 default = nil)
  if valid_606451 != nil:
    section.add "X-Amz-Content-Sha256", valid_606451
  var valid_606452 = header.getOrDefault("X-Amz-Date")
  valid_606452 = validateParameter(valid_606452, JString, required = false,
                                 default = nil)
  if valid_606452 != nil:
    section.add "X-Amz-Date", valid_606452
  var valid_606453 = header.getOrDefault("X-Amz-Credential")
  valid_606453 = validateParameter(valid_606453, JString, required = false,
                                 default = nil)
  if valid_606453 != nil:
    section.add "X-Amz-Credential", valid_606453
  var valid_606454 = header.getOrDefault("X-Amz-Security-Token")
  valid_606454 = validateParameter(valid_606454, JString, required = false,
                                 default = nil)
  if valid_606454 != nil:
    section.add "X-Amz-Security-Token", valid_606454
  var valid_606455 = header.getOrDefault("X-Amz-Algorithm")
  valid_606455 = validateParameter(valid_606455, JString, required = false,
                                 default = nil)
  if valid_606455 != nil:
    section.add "X-Amz-Algorithm", valid_606455
  var valid_606456 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606456 = validateParameter(valid_606456, JString, required = false,
                                 default = nil)
  if valid_606456 != nil:
    section.add "X-Amz-SignedHeaders", valid_606456
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606458: Call_ListTagsForStream_606446; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags for the specified Kinesis data stream. This operation has a limit of five transactions per second per account.
  ## 
  let valid = call_606458.validator(path, query, header, formData, body)
  let scheme = call_606458.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606458.url(scheme.get, call_606458.host, call_606458.base,
                         call_606458.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606458, url, valid)

proc call*(call_606459: Call_ListTagsForStream_606446; body: JsonNode): Recallable =
  ## listTagsForStream
  ## Lists the tags for the specified Kinesis data stream. This operation has a limit of five transactions per second per account.
  ##   body: JObject (required)
  var body_606460 = newJObject()
  if body != nil:
    body_606460 = body
  result = call_606459.call(nil, nil, nil, nil, body_606460)

var listTagsForStream* = Call_ListTagsForStream_606446(name: "listTagsForStream",
    meth: HttpMethod.HttpPost, host: "kinesis.amazonaws.com",
    route: "/#X-Amz-Target=Kinesis_20131202.ListTagsForStream",
    validator: validate_ListTagsForStream_606447, base: "/",
    url: url_ListTagsForStream_606448, schemes: {Scheme.Https, Scheme.Http})
type
  Call_MergeShards_606461 = ref object of OpenApiRestCall_605589
proc url_MergeShards_606463(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_MergeShards_606462(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Merges two adjacent shards in a Kinesis data stream and combines them into a single shard to reduce the stream's capacity to ingest and transport data. Two shards are considered adjacent if the union of the hash key ranges for the two shards form a contiguous set with no gaps. For example, if you have two shards, one with a hash key range of 276...381 and the other with a hash key range of 382...454, then you could merge these two shards into a single shard that would have a hash key range of 276...454. After the merge, the single child shard receives data for all hash key values covered by the two parent shards.</p> <p> <code>MergeShards</code> is called when there is a need to reduce the overall capacity of a stream because of excess capacity that is not being used. You must specify the shard to be merged and the adjacent shard for a stream. For more information about merging shards, see <a href="http://docs.aws.amazon.com/kinesis/latest/dev/kinesis-using-sdk-java-resharding-merge.html">Merge Two Shards</a> in the <i>Amazon Kinesis Data Streams Developer Guide</i>.</p> <p>If the stream is in the <code>ACTIVE</code> state, you can call <code>MergeShards</code>. If a stream is in the <code>CREATING</code>, <code>UPDATING</code>, or <code>DELETING</code> state, <code>MergeShards</code> returns a <code>ResourceInUseException</code>. If the specified stream does not exist, <code>MergeShards</code> returns a <code>ResourceNotFoundException</code>. </p> <p>You can use <a>DescribeStream</a> to check the state of the stream, which is returned in <code>StreamStatus</code>.</p> <p> <code>MergeShards</code> is an asynchronous operation. Upon receiving a <code>MergeShards</code> request, Amazon Kinesis Data Streams immediately returns a response and sets the <code>StreamStatus</code> to <code>UPDATING</code>. After the operation is completed, Kinesis Data Streams sets the <code>StreamStatus</code> to <code>ACTIVE</code>. Read and write operations continue to work while the stream is in the <code>UPDATING</code> state. </p> <p>You use <a>DescribeStream</a> to determine the shard IDs that are specified in the <code>MergeShards</code> request. </p> <p>If you try to operate on too many streams in parallel using <a>CreateStream</a>, <a>DeleteStream</a>, <code>MergeShards</code>, or <a>SplitShard</a>, you receive a <code>LimitExceededException</code>. </p> <p> <code>MergeShards</code> has a limit of five transactions per second per account.</p>
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
  var valid_606464 = header.getOrDefault("X-Amz-Target")
  valid_606464 = validateParameter(valid_606464, JString, required = true, default = newJString(
      "Kinesis_20131202.MergeShards"))
  if valid_606464 != nil:
    section.add "X-Amz-Target", valid_606464
  var valid_606465 = header.getOrDefault("X-Amz-Signature")
  valid_606465 = validateParameter(valid_606465, JString, required = false,
                                 default = nil)
  if valid_606465 != nil:
    section.add "X-Amz-Signature", valid_606465
  var valid_606466 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606466 = validateParameter(valid_606466, JString, required = false,
                                 default = nil)
  if valid_606466 != nil:
    section.add "X-Amz-Content-Sha256", valid_606466
  var valid_606467 = header.getOrDefault("X-Amz-Date")
  valid_606467 = validateParameter(valid_606467, JString, required = false,
                                 default = nil)
  if valid_606467 != nil:
    section.add "X-Amz-Date", valid_606467
  var valid_606468 = header.getOrDefault("X-Amz-Credential")
  valid_606468 = validateParameter(valid_606468, JString, required = false,
                                 default = nil)
  if valid_606468 != nil:
    section.add "X-Amz-Credential", valid_606468
  var valid_606469 = header.getOrDefault("X-Amz-Security-Token")
  valid_606469 = validateParameter(valid_606469, JString, required = false,
                                 default = nil)
  if valid_606469 != nil:
    section.add "X-Amz-Security-Token", valid_606469
  var valid_606470 = header.getOrDefault("X-Amz-Algorithm")
  valid_606470 = validateParameter(valid_606470, JString, required = false,
                                 default = nil)
  if valid_606470 != nil:
    section.add "X-Amz-Algorithm", valid_606470
  var valid_606471 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606471 = validateParameter(valid_606471, JString, required = false,
                                 default = nil)
  if valid_606471 != nil:
    section.add "X-Amz-SignedHeaders", valid_606471
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606473: Call_MergeShards_606461; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Merges two adjacent shards in a Kinesis data stream and combines them into a single shard to reduce the stream's capacity to ingest and transport data. Two shards are considered adjacent if the union of the hash key ranges for the two shards form a contiguous set with no gaps. For example, if you have two shards, one with a hash key range of 276...381 and the other with a hash key range of 382...454, then you could merge these two shards into a single shard that would have a hash key range of 276...454. After the merge, the single child shard receives data for all hash key values covered by the two parent shards.</p> <p> <code>MergeShards</code> is called when there is a need to reduce the overall capacity of a stream because of excess capacity that is not being used. You must specify the shard to be merged and the adjacent shard for a stream. For more information about merging shards, see <a href="http://docs.aws.amazon.com/kinesis/latest/dev/kinesis-using-sdk-java-resharding-merge.html">Merge Two Shards</a> in the <i>Amazon Kinesis Data Streams Developer Guide</i>.</p> <p>If the stream is in the <code>ACTIVE</code> state, you can call <code>MergeShards</code>. If a stream is in the <code>CREATING</code>, <code>UPDATING</code>, or <code>DELETING</code> state, <code>MergeShards</code> returns a <code>ResourceInUseException</code>. If the specified stream does not exist, <code>MergeShards</code> returns a <code>ResourceNotFoundException</code>. </p> <p>You can use <a>DescribeStream</a> to check the state of the stream, which is returned in <code>StreamStatus</code>.</p> <p> <code>MergeShards</code> is an asynchronous operation. Upon receiving a <code>MergeShards</code> request, Amazon Kinesis Data Streams immediately returns a response and sets the <code>StreamStatus</code> to <code>UPDATING</code>. After the operation is completed, Kinesis Data Streams sets the <code>StreamStatus</code> to <code>ACTIVE</code>. Read and write operations continue to work while the stream is in the <code>UPDATING</code> state. </p> <p>You use <a>DescribeStream</a> to determine the shard IDs that are specified in the <code>MergeShards</code> request. </p> <p>If you try to operate on too many streams in parallel using <a>CreateStream</a>, <a>DeleteStream</a>, <code>MergeShards</code>, or <a>SplitShard</a>, you receive a <code>LimitExceededException</code>. </p> <p> <code>MergeShards</code> has a limit of five transactions per second per account.</p>
  ## 
  let valid = call_606473.validator(path, query, header, formData, body)
  let scheme = call_606473.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606473.url(scheme.get, call_606473.host, call_606473.base,
                         call_606473.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606473, url, valid)

proc call*(call_606474: Call_MergeShards_606461; body: JsonNode): Recallable =
  ## mergeShards
  ## <p>Merges two adjacent shards in a Kinesis data stream and combines them into a single shard to reduce the stream's capacity to ingest and transport data. Two shards are considered adjacent if the union of the hash key ranges for the two shards form a contiguous set with no gaps. For example, if you have two shards, one with a hash key range of 276...381 and the other with a hash key range of 382...454, then you could merge these two shards into a single shard that would have a hash key range of 276...454. After the merge, the single child shard receives data for all hash key values covered by the two parent shards.</p> <p> <code>MergeShards</code> is called when there is a need to reduce the overall capacity of a stream because of excess capacity that is not being used. You must specify the shard to be merged and the adjacent shard for a stream. For more information about merging shards, see <a href="http://docs.aws.amazon.com/kinesis/latest/dev/kinesis-using-sdk-java-resharding-merge.html">Merge Two Shards</a> in the <i>Amazon Kinesis Data Streams Developer Guide</i>.</p> <p>If the stream is in the <code>ACTIVE</code> state, you can call <code>MergeShards</code>. If a stream is in the <code>CREATING</code>, <code>UPDATING</code>, or <code>DELETING</code> state, <code>MergeShards</code> returns a <code>ResourceInUseException</code>. If the specified stream does not exist, <code>MergeShards</code> returns a <code>ResourceNotFoundException</code>. </p> <p>You can use <a>DescribeStream</a> to check the state of the stream, which is returned in <code>StreamStatus</code>.</p> <p> <code>MergeShards</code> is an asynchronous operation. Upon receiving a <code>MergeShards</code> request, Amazon Kinesis Data Streams immediately returns a response and sets the <code>StreamStatus</code> to <code>UPDATING</code>. After the operation is completed, Kinesis Data Streams sets the <code>StreamStatus</code> to <code>ACTIVE</code>. Read and write operations continue to work while the stream is in the <code>UPDATING</code> state. </p> <p>You use <a>DescribeStream</a> to determine the shard IDs that are specified in the <code>MergeShards</code> request. </p> <p>If you try to operate on too many streams in parallel using <a>CreateStream</a>, <a>DeleteStream</a>, <code>MergeShards</code>, or <a>SplitShard</a>, you receive a <code>LimitExceededException</code>. </p> <p> <code>MergeShards</code> has a limit of five transactions per second per account.</p>
  ##   body: JObject (required)
  var body_606475 = newJObject()
  if body != nil:
    body_606475 = body
  result = call_606474.call(nil, nil, nil, nil, body_606475)

var mergeShards* = Call_MergeShards_606461(name: "mergeShards",
                                        meth: HttpMethod.HttpPost,
                                        host: "kinesis.amazonaws.com", route: "/#X-Amz-Target=Kinesis_20131202.MergeShards",
                                        validator: validate_MergeShards_606462,
                                        base: "/", url: url_MergeShards_606463,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutRecord_606476 = ref object of OpenApiRestCall_605589
proc url_PutRecord_606478(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutRecord_606477(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Writes a single data record into an Amazon Kinesis data stream. Call <code>PutRecord</code> to send data into the stream for real-time ingestion and subsequent processing, one record at a time. Each shard can support writes up to 1,000 records per second, up to a maximum data write total of 1 MB per second.</p> <p>You must specify the name of the stream that captures, stores, and transports the data; a partition key; and the data blob itself.</p> <p>The data blob can be any type of data; for example, a segment from a log file, geographic/location data, website clickstream data, and so on.</p> <p>The partition key is used by Kinesis Data Streams to distribute data across shards. Kinesis Data Streams segregates the data records that belong to a stream into multiple shards, using the partition key associated with each data record to determine the shard to which a given data record belongs.</p> <p>Partition keys are Unicode strings, with a maximum length limit of 256 characters for each key. An MD5 hash function is used to map partition keys to 128-bit integer values and to map associated data records to shards using the hash key ranges of the shards. You can override hashing the partition key to determine the shard by explicitly specifying a hash value using the <code>ExplicitHashKey</code> parameter. For more information, see <a href="http://docs.aws.amazon.com/kinesis/latest/dev/developing-producers-with-sdk.html#kinesis-using-sdk-java-add-data-to-stream">Adding Data to a Stream</a> in the <i>Amazon Kinesis Data Streams Developer Guide</i>.</p> <p> <code>PutRecord</code> returns the shard ID of where the data record was placed and the sequence number that was assigned to the data record.</p> <p>Sequence numbers increase over time and are specific to a shard within a stream, not across all shards within a stream. To guarantee strictly increasing ordering, write serially to a shard and use the <code>SequenceNumberForOrdering</code> parameter. For more information, see <a href="http://docs.aws.amazon.com/kinesis/latest/dev/developing-producers-with-sdk.html#kinesis-using-sdk-java-add-data-to-stream">Adding Data to a Stream</a> in the <i>Amazon Kinesis Data Streams Developer Guide</i>.</p> <p>If a <code>PutRecord</code> request cannot be processed because of insufficient provisioned throughput on the shard involved in the request, <code>PutRecord</code> throws <code>ProvisionedThroughputExceededException</code>. </p> <p>By default, data records are accessible for 24 hours from the time that they are added to a stream. You can use <a>IncreaseStreamRetentionPeriod</a> or <a>DecreaseStreamRetentionPeriod</a> to modify this retention period.</p>
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
  var valid_606479 = header.getOrDefault("X-Amz-Target")
  valid_606479 = validateParameter(valid_606479, JString, required = true, default = newJString(
      "Kinesis_20131202.PutRecord"))
  if valid_606479 != nil:
    section.add "X-Amz-Target", valid_606479
  var valid_606480 = header.getOrDefault("X-Amz-Signature")
  valid_606480 = validateParameter(valid_606480, JString, required = false,
                                 default = nil)
  if valid_606480 != nil:
    section.add "X-Amz-Signature", valid_606480
  var valid_606481 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606481 = validateParameter(valid_606481, JString, required = false,
                                 default = nil)
  if valid_606481 != nil:
    section.add "X-Amz-Content-Sha256", valid_606481
  var valid_606482 = header.getOrDefault("X-Amz-Date")
  valid_606482 = validateParameter(valid_606482, JString, required = false,
                                 default = nil)
  if valid_606482 != nil:
    section.add "X-Amz-Date", valid_606482
  var valid_606483 = header.getOrDefault("X-Amz-Credential")
  valid_606483 = validateParameter(valid_606483, JString, required = false,
                                 default = nil)
  if valid_606483 != nil:
    section.add "X-Amz-Credential", valid_606483
  var valid_606484 = header.getOrDefault("X-Amz-Security-Token")
  valid_606484 = validateParameter(valid_606484, JString, required = false,
                                 default = nil)
  if valid_606484 != nil:
    section.add "X-Amz-Security-Token", valid_606484
  var valid_606485 = header.getOrDefault("X-Amz-Algorithm")
  valid_606485 = validateParameter(valid_606485, JString, required = false,
                                 default = nil)
  if valid_606485 != nil:
    section.add "X-Amz-Algorithm", valid_606485
  var valid_606486 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606486 = validateParameter(valid_606486, JString, required = false,
                                 default = nil)
  if valid_606486 != nil:
    section.add "X-Amz-SignedHeaders", valid_606486
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606488: Call_PutRecord_606476; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Writes a single data record into an Amazon Kinesis data stream. Call <code>PutRecord</code> to send data into the stream for real-time ingestion and subsequent processing, one record at a time. Each shard can support writes up to 1,000 records per second, up to a maximum data write total of 1 MB per second.</p> <p>You must specify the name of the stream that captures, stores, and transports the data; a partition key; and the data blob itself.</p> <p>The data blob can be any type of data; for example, a segment from a log file, geographic/location data, website clickstream data, and so on.</p> <p>The partition key is used by Kinesis Data Streams to distribute data across shards. Kinesis Data Streams segregates the data records that belong to a stream into multiple shards, using the partition key associated with each data record to determine the shard to which a given data record belongs.</p> <p>Partition keys are Unicode strings, with a maximum length limit of 256 characters for each key. An MD5 hash function is used to map partition keys to 128-bit integer values and to map associated data records to shards using the hash key ranges of the shards. You can override hashing the partition key to determine the shard by explicitly specifying a hash value using the <code>ExplicitHashKey</code> parameter. For more information, see <a href="http://docs.aws.amazon.com/kinesis/latest/dev/developing-producers-with-sdk.html#kinesis-using-sdk-java-add-data-to-stream">Adding Data to a Stream</a> in the <i>Amazon Kinesis Data Streams Developer Guide</i>.</p> <p> <code>PutRecord</code> returns the shard ID of where the data record was placed and the sequence number that was assigned to the data record.</p> <p>Sequence numbers increase over time and are specific to a shard within a stream, not across all shards within a stream. To guarantee strictly increasing ordering, write serially to a shard and use the <code>SequenceNumberForOrdering</code> parameter. For more information, see <a href="http://docs.aws.amazon.com/kinesis/latest/dev/developing-producers-with-sdk.html#kinesis-using-sdk-java-add-data-to-stream">Adding Data to a Stream</a> in the <i>Amazon Kinesis Data Streams Developer Guide</i>.</p> <p>If a <code>PutRecord</code> request cannot be processed because of insufficient provisioned throughput on the shard involved in the request, <code>PutRecord</code> throws <code>ProvisionedThroughputExceededException</code>. </p> <p>By default, data records are accessible for 24 hours from the time that they are added to a stream. You can use <a>IncreaseStreamRetentionPeriod</a> or <a>DecreaseStreamRetentionPeriod</a> to modify this retention period.</p>
  ## 
  let valid = call_606488.validator(path, query, header, formData, body)
  let scheme = call_606488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606488.url(scheme.get, call_606488.host, call_606488.base,
                         call_606488.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606488, url, valid)

proc call*(call_606489: Call_PutRecord_606476; body: JsonNode): Recallable =
  ## putRecord
  ## <p>Writes a single data record into an Amazon Kinesis data stream. Call <code>PutRecord</code> to send data into the stream for real-time ingestion and subsequent processing, one record at a time. Each shard can support writes up to 1,000 records per second, up to a maximum data write total of 1 MB per second.</p> <p>You must specify the name of the stream that captures, stores, and transports the data; a partition key; and the data blob itself.</p> <p>The data blob can be any type of data; for example, a segment from a log file, geographic/location data, website clickstream data, and so on.</p> <p>The partition key is used by Kinesis Data Streams to distribute data across shards. Kinesis Data Streams segregates the data records that belong to a stream into multiple shards, using the partition key associated with each data record to determine the shard to which a given data record belongs.</p> <p>Partition keys are Unicode strings, with a maximum length limit of 256 characters for each key. An MD5 hash function is used to map partition keys to 128-bit integer values and to map associated data records to shards using the hash key ranges of the shards. You can override hashing the partition key to determine the shard by explicitly specifying a hash value using the <code>ExplicitHashKey</code> parameter. For more information, see <a href="http://docs.aws.amazon.com/kinesis/latest/dev/developing-producers-with-sdk.html#kinesis-using-sdk-java-add-data-to-stream">Adding Data to a Stream</a> in the <i>Amazon Kinesis Data Streams Developer Guide</i>.</p> <p> <code>PutRecord</code> returns the shard ID of where the data record was placed and the sequence number that was assigned to the data record.</p> <p>Sequence numbers increase over time and are specific to a shard within a stream, not across all shards within a stream. To guarantee strictly increasing ordering, write serially to a shard and use the <code>SequenceNumberForOrdering</code> parameter. For more information, see <a href="http://docs.aws.amazon.com/kinesis/latest/dev/developing-producers-with-sdk.html#kinesis-using-sdk-java-add-data-to-stream">Adding Data to a Stream</a> in the <i>Amazon Kinesis Data Streams Developer Guide</i>.</p> <p>If a <code>PutRecord</code> request cannot be processed because of insufficient provisioned throughput on the shard involved in the request, <code>PutRecord</code> throws <code>ProvisionedThroughputExceededException</code>. </p> <p>By default, data records are accessible for 24 hours from the time that they are added to a stream. You can use <a>IncreaseStreamRetentionPeriod</a> or <a>DecreaseStreamRetentionPeriod</a> to modify this retention period.</p>
  ##   body: JObject (required)
  var body_606490 = newJObject()
  if body != nil:
    body_606490 = body
  result = call_606489.call(nil, nil, nil, nil, body_606490)

var putRecord* = Call_PutRecord_606476(name: "putRecord", meth: HttpMethod.HttpPost,
                                    host: "kinesis.amazonaws.com", route: "/#X-Amz-Target=Kinesis_20131202.PutRecord",
                                    validator: validate_PutRecord_606477,
                                    base: "/", url: url_PutRecord_606478,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutRecords_606491 = ref object of OpenApiRestCall_605589
proc url_PutRecords_606493(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutRecords_606492(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Writes multiple data records into a Kinesis data stream in a single call (also referred to as a <code>PutRecords</code> request). Use this operation to send data into the stream for data ingestion and processing. </p> <p>Each <code>PutRecords</code> request can support up to 500 records. Each record in the request can be as large as 1 MB, up to a limit of 5 MB for the entire request, including partition keys. Each shard can support writes up to 1,000 records per second, up to a maximum data write total of 1 MB per second.</p> <p>You must specify the name of the stream that captures, stores, and transports the data; and an array of request <code>Records</code>, with each record in the array requiring a partition key and data blob. The record size limit applies to the total size of the partition key and data blob.</p> <p>The data blob can be any type of data; for example, a segment from a log file, geographic/location data, website clickstream data, and so on.</p> <p>The partition key is used by Kinesis Data Streams as input to a hash function that maps the partition key and associated data to a specific shard. An MD5 hash function is used to map partition keys to 128-bit integer values and to map associated data records to shards. As a result of this hashing mechanism, all data records with the same partition key map to the same shard within the stream. For more information, see <a href="http://docs.aws.amazon.com/kinesis/latest/dev/developing-producers-with-sdk.html#kinesis-using-sdk-java-add-data-to-stream">Adding Data to a Stream</a> in the <i>Amazon Kinesis Data Streams Developer Guide</i>.</p> <p>Each record in the <code>Records</code> array may include an optional parameter, <code>ExplicitHashKey</code>, which overrides the partition key to shard mapping. This parameter allows a data producer to determine explicitly the shard where the record is stored. For more information, see <a href="http://docs.aws.amazon.com/kinesis/latest/dev/developing-producers-with-sdk.html#kinesis-using-sdk-java-putrecords">Adding Multiple Records with PutRecords</a> in the <i>Amazon Kinesis Data Streams Developer Guide</i>.</p> <p>The <code>PutRecords</code> response includes an array of response <code>Records</code>. Each record in the response array directly correlates with a record in the request array using natural ordering, from the top to the bottom of the request and response. The response <code>Records</code> array always includes the same number of records as the request array.</p> <p>The response <code>Records</code> array includes both successfully and unsuccessfully processed records. Kinesis Data Streams attempts to process all records in each <code>PutRecords</code> request. A single record failure does not stop the processing of subsequent records.</p> <p>A successfully processed record includes <code>ShardId</code> and <code>SequenceNumber</code> values. The <code>ShardId</code> parameter identifies the shard in the stream where the record is stored. The <code>SequenceNumber</code> parameter is an identifier assigned to the put record, unique to all records in the stream.</p> <p>An unsuccessfully processed record includes <code>ErrorCode</code> and <code>ErrorMessage</code> values. <code>ErrorCode</code> reflects the type of error and can be one of the following values: <code>ProvisionedThroughputExceededException</code> or <code>InternalFailure</code>. <code>ErrorMessage</code> provides more detailed information about the <code>ProvisionedThroughputExceededException</code> exception including the account ID, stream name, and shard ID of the record that was throttled. For more information about partially successful responses, see <a href="http://docs.aws.amazon.com/kinesis/latest/dev/kinesis-using-sdk-java-add-data-to-stream.html#kinesis-using-sdk-java-putrecords">Adding Multiple Records with PutRecords</a> in the <i>Amazon Kinesis Data Streams Developer Guide</i>.</p> <p>By default, data records are accessible for 24 hours from the time that they are added to a stream. You can use <a>IncreaseStreamRetentionPeriod</a> or <a>DecreaseStreamRetentionPeriod</a> to modify this retention period.</p>
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
  var valid_606494 = header.getOrDefault("X-Amz-Target")
  valid_606494 = validateParameter(valid_606494, JString, required = true, default = newJString(
      "Kinesis_20131202.PutRecords"))
  if valid_606494 != nil:
    section.add "X-Amz-Target", valid_606494
  var valid_606495 = header.getOrDefault("X-Amz-Signature")
  valid_606495 = validateParameter(valid_606495, JString, required = false,
                                 default = nil)
  if valid_606495 != nil:
    section.add "X-Amz-Signature", valid_606495
  var valid_606496 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606496 = validateParameter(valid_606496, JString, required = false,
                                 default = nil)
  if valid_606496 != nil:
    section.add "X-Amz-Content-Sha256", valid_606496
  var valid_606497 = header.getOrDefault("X-Amz-Date")
  valid_606497 = validateParameter(valid_606497, JString, required = false,
                                 default = nil)
  if valid_606497 != nil:
    section.add "X-Amz-Date", valid_606497
  var valid_606498 = header.getOrDefault("X-Amz-Credential")
  valid_606498 = validateParameter(valid_606498, JString, required = false,
                                 default = nil)
  if valid_606498 != nil:
    section.add "X-Amz-Credential", valid_606498
  var valid_606499 = header.getOrDefault("X-Amz-Security-Token")
  valid_606499 = validateParameter(valid_606499, JString, required = false,
                                 default = nil)
  if valid_606499 != nil:
    section.add "X-Amz-Security-Token", valid_606499
  var valid_606500 = header.getOrDefault("X-Amz-Algorithm")
  valid_606500 = validateParameter(valid_606500, JString, required = false,
                                 default = nil)
  if valid_606500 != nil:
    section.add "X-Amz-Algorithm", valid_606500
  var valid_606501 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606501 = validateParameter(valid_606501, JString, required = false,
                                 default = nil)
  if valid_606501 != nil:
    section.add "X-Amz-SignedHeaders", valid_606501
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606503: Call_PutRecords_606491; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Writes multiple data records into a Kinesis data stream in a single call (also referred to as a <code>PutRecords</code> request). Use this operation to send data into the stream for data ingestion and processing. </p> <p>Each <code>PutRecords</code> request can support up to 500 records. Each record in the request can be as large as 1 MB, up to a limit of 5 MB for the entire request, including partition keys. Each shard can support writes up to 1,000 records per second, up to a maximum data write total of 1 MB per second.</p> <p>You must specify the name of the stream that captures, stores, and transports the data; and an array of request <code>Records</code>, with each record in the array requiring a partition key and data blob. The record size limit applies to the total size of the partition key and data blob.</p> <p>The data blob can be any type of data; for example, a segment from a log file, geographic/location data, website clickstream data, and so on.</p> <p>The partition key is used by Kinesis Data Streams as input to a hash function that maps the partition key and associated data to a specific shard. An MD5 hash function is used to map partition keys to 128-bit integer values and to map associated data records to shards. As a result of this hashing mechanism, all data records with the same partition key map to the same shard within the stream. For more information, see <a href="http://docs.aws.amazon.com/kinesis/latest/dev/developing-producers-with-sdk.html#kinesis-using-sdk-java-add-data-to-stream">Adding Data to a Stream</a> in the <i>Amazon Kinesis Data Streams Developer Guide</i>.</p> <p>Each record in the <code>Records</code> array may include an optional parameter, <code>ExplicitHashKey</code>, which overrides the partition key to shard mapping. This parameter allows a data producer to determine explicitly the shard where the record is stored. For more information, see <a href="http://docs.aws.amazon.com/kinesis/latest/dev/developing-producers-with-sdk.html#kinesis-using-sdk-java-putrecords">Adding Multiple Records with PutRecords</a> in the <i>Amazon Kinesis Data Streams Developer Guide</i>.</p> <p>The <code>PutRecords</code> response includes an array of response <code>Records</code>. Each record in the response array directly correlates with a record in the request array using natural ordering, from the top to the bottom of the request and response. The response <code>Records</code> array always includes the same number of records as the request array.</p> <p>The response <code>Records</code> array includes both successfully and unsuccessfully processed records. Kinesis Data Streams attempts to process all records in each <code>PutRecords</code> request. A single record failure does not stop the processing of subsequent records.</p> <p>A successfully processed record includes <code>ShardId</code> and <code>SequenceNumber</code> values. The <code>ShardId</code> parameter identifies the shard in the stream where the record is stored. The <code>SequenceNumber</code> parameter is an identifier assigned to the put record, unique to all records in the stream.</p> <p>An unsuccessfully processed record includes <code>ErrorCode</code> and <code>ErrorMessage</code> values. <code>ErrorCode</code> reflects the type of error and can be one of the following values: <code>ProvisionedThroughputExceededException</code> or <code>InternalFailure</code>. <code>ErrorMessage</code> provides more detailed information about the <code>ProvisionedThroughputExceededException</code> exception including the account ID, stream name, and shard ID of the record that was throttled. For more information about partially successful responses, see <a href="http://docs.aws.amazon.com/kinesis/latest/dev/kinesis-using-sdk-java-add-data-to-stream.html#kinesis-using-sdk-java-putrecords">Adding Multiple Records with PutRecords</a> in the <i>Amazon Kinesis Data Streams Developer Guide</i>.</p> <p>By default, data records are accessible for 24 hours from the time that they are added to a stream. You can use <a>IncreaseStreamRetentionPeriod</a> or <a>DecreaseStreamRetentionPeriod</a> to modify this retention period.</p>
  ## 
  let valid = call_606503.validator(path, query, header, formData, body)
  let scheme = call_606503.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606503.url(scheme.get, call_606503.host, call_606503.base,
                         call_606503.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606503, url, valid)

proc call*(call_606504: Call_PutRecords_606491; body: JsonNode): Recallable =
  ## putRecords
  ## <p>Writes multiple data records into a Kinesis data stream in a single call (also referred to as a <code>PutRecords</code> request). Use this operation to send data into the stream for data ingestion and processing. </p> <p>Each <code>PutRecords</code> request can support up to 500 records. Each record in the request can be as large as 1 MB, up to a limit of 5 MB for the entire request, including partition keys. Each shard can support writes up to 1,000 records per second, up to a maximum data write total of 1 MB per second.</p> <p>You must specify the name of the stream that captures, stores, and transports the data; and an array of request <code>Records</code>, with each record in the array requiring a partition key and data blob. The record size limit applies to the total size of the partition key and data blob.</p> <p>The data blob can be any type of data; for example, a segment from a log file, geographic/location data, website clickstream data, and so on.</p> <p>The partition key is used by Kinesis Data Streams as input to a hash function that maps the partition key and associated data to a specific shard. An MD5 hash function is used to map partition keys to 128-bit integer values and to map associated data records to shards. As a result of this hashing mechanism, all data records with the same partition key map to the same shard within the stream. For more information, see <a href="http://docs.aws.amazon.com/kinesis/latest/dev/developing-producers-with-sdk.html#kinesis-using-sdk-java-add-data-to-stream">Adding Data to a Stream</a> in the <i>Amazon Kinesis Data Streams Developer Guide</i>.</p> <p>Each record in the <code>Records</code> array may include an optional parameter, <code>ExplicitHashKey</code>, which overrides the partition key to shard mapping. This parameter allows a data producer to determine explicitly the shard where the record is stored. For more information, see <a href="http://docs.aws.amazon.com/kinesis/latest/dev/developing-producers-with-sdk.html#kinesis-using-sdk-java-putrecords">Adding Multiple Records with PutRecords</a> in the <i>Amazon Kinesis Data Streams Developer Guide</i>.</p> <p>The <code>PutRecords</code> response includes an array of response <code>Records</code>. Each record in the response array directly correlates with a record in the request array using natural ordering, from the top to the bottom of the request and response. The response <code>Records</code> array always includes the same number of records as the request array.</p> <p>The response <code>Records</code> array includes both successfully and unsuccessfully processed records. Kinesis Data Streams attempts to process all records in each <code>PutRecords</code> request. A single record failure does not stop the processing of subsequent records.</p> <p>A successfully processed record includes <code>ShardId</code> and <code>SequenceNumber</code> values. The <code>ShardId</code> parameter identifies the shard in the stream where the record is stored. The <code>SequenceNumber</code> parameter is an identifier assigned to the put record, unique to all records in the stream.</p> <p>An unsuccessfully processed record includes <code>ErrorCode</code> and <code>ErrorMessage</code> values. <code>ErrorCode</code> reflects the type of error and can be one of the following values: <code>ProvisionedThroughputExceededException</code> or <code>InternalFailure</code>. <code>ErrorMessage</code> provides more detailed information about the <code>ProvisionedThroughputExceededException</code> exception including the account ID, stream name, and shard ID of the record that was throttled. For more information about partially successful responses, see <a href="http://docs.aws.amazon.com/kinesis/latest/dev/kinesis-using-sdk-java-add-data-to-stream.html#kinesis-using-sdk-java-putrecords">Adding Multiple Records with PutRecords</a> in the <i>Amazon Kinesis Data Streams Developer Guide</i>.</p> <p>By default, data records are accessible for 24 hours from the time that they are added to a stream. You can use <a>IncreaseStreamRetentionPeriod</a> or <a>DecreaseStreamRetentionPeriod</a> to modify this retention period.</p>
  ##   body: JObject (required)
  var body_606505 = newJObject()
  if body != nil:
    body_606505 = body
  result = call_606504.call(nil, nil, nil, nil, body_606505)

var putRecords* = Call_PutRecords_606491(name: "putRecords",
                                      meth: HttpMethod.HttpPost,
                                      host: "kinesis.amazonaws.com", route: "/#X-Amz-Target=Kinesis_20131202.PutRecords",
                                      validator: validate_PutRecords_606492,
                                      base: "/", url: url_PutRecords_606493,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterStreamConsumer_606506 = ref object of OpenApiRestCall_605589
proc url_RegisterStreamConsumer_606508(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RegisterStreamConsumer_606507(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Registers a consumer with a Kinesis data stream. When you use this operation, the consumer you register can read data from the stream at a rate of up to 2 MiB per second. This rate is unaffected by the total number of consumers that read from the same stream.</p> <p>You can register up to 5 consumers per stream. A given consumer can only be registered with one stream.</p> <p>This operation has a limit of five transactions per second per account.</p>
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
  var valid_606509 = header.getOrDefault("X-Amz-Target")
  valid_606509 = validateParameter(valid_606509, JString, required = true, default = newJString(
      "Kinesis_20131202.RegisterStreamConsumer"))
  if valid_606509 != nil:
    section.add "X-Amz-Target", valid_606509
  var valid_606510 = header.getOrDefault("X-Amz-Signature")
  valid_606510 = validateParameter(valid_606510, JString, required = false,
                                 default = nil)
  if valid_606510 != nil:
    section.add "X-Amz-Signature", valid_606510
  var valid_606511 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606511 = validateParameter(valid_606511, JString, required = false,
                                 default = nil)
  if valid_606511 != nil:
    section.add "X-Amz-Content-Sha256", valid_606511
  var valid_606512 = header.getOrDefault("X-Amz-Date")
  valid_606512 = validateParameter(valid_606512, JString, required = false,
                                 default = nil)
  if valid_606512 != nil:
    section.add "X-Amz-Date", valid_606512
  var valid_606513 = header.getOrDefault("X-Amz-Credential")
  valid_606513 = validateParameter(valid_606513, JString, required = false,
                                 default = nil)
  if valid_606513 != nil:
    section.add "X-Amz-Credential", valid_606513
  var valid_606514 = header.getOrDefault("X-Amz-Security-Token")
  valid_606514 = validateParameter(valid_606514, JString, required = false,
                                 default = nil)
  if valid_606514 != nil:
    section.add "X-Amz-Security-Token", valid_606514
  var valid_606515 = header.getOrDefault("X-Amz-Algorithm")
  valid_606515 = validateParameter(valid_606515, JString, required = false,
                                 default = nil)
  if valid_606515 != nil:
    section.add "X-Amz-Algorithm", valid_606515
  var valid_606516 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606516 = validateParameter(valid_606516, JString, required = false,
                                 default = nil)
  if valid_606516 != nil:
    section.add "X-Amz-SignedHeaders", valid_606516
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606518: Call_RegisterStreamConsumer_606506; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Registers a consumer with a Kinesis data stream. When you use this operation, the consumer you register can read data from the stream at a rate of up to 2 MiB per second. This rate is unaffected by the total number of consumers that read from the same stream.</p> <p>You can register up to 5 consumers per stream. A given consumer can only be registered with one stream.</p> <p>This operation has a limit of five transactions per second per account.</p>
  ## 
  let valid = call_606518.validator(path, query, header, formData, body)
  let scheme = call_606518.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606518.url(scheme.get, call_606518.host, call_606518.base,
                         call_606518.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606518, url, valid)

proc call*(call_606519: Call_RegisterStreamConsumer_606506; body: JsonNode): Recallable =
  ## registerStreamConsumer
  ## <p>Registers a consumer with a Kinesis data stream. When you use this operation, the consumer you register can read data from the stream at a rate of up to 2 MiB per second. This rate is unaffected by the total number of consumers that read from the same stream.</p> <p>You can register up to 5 consumers per stream. A given consumer can only be registered with one stream.</p> <p>This operation has a limit of five transactions per second per account.</p>
  ##   body: JObject (required)
  var body_606520 = newJObject()
  if body != nil:
    body_606520 = body
  result = call_606519.call(nil, nil, nil, nil, body_606520)

var registerStreamConsumer* = Call_RegisterStreamConsumer_606506(
    name: "registerStreamConsumer", meth: HttpMethod.HttpPost,
    host: "kinesis.amazonaws.com",
    route: "/#X-Amz-Target=Kinesis_20131202.RegisterStreamConsumer",
    validator: validate_RegisterStreamConsumer_606507, base: "/",
    url: url_RegisterStreamConsumer_606508, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveTagsFromStream_606521 = ref object of OpenApiRestCall_605589
proc url_RemoveTagsFromStream_606523(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RemoveTagsFromStream_606522(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Removes tags from the specified Kinesis data stream. Removed tags are deleted and cannot be recovered after this operation successfully completes.</p> <p>If you specify a tag that does not exist, it is ignored.</p> <p> <a>RemoveTagsFromStream</a> has a limit of five transactions per second per account.</p>
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
  var valid_606524 = header.getOrDefault("X-Amz-Target")
  valid_606524 = validateParameter(valid_606524, JString, required = true, default = newJString(
      "Kinesis_20131202.RemoveTagsFromStream"))
  if valid_606524 != nil:
    section.add "X-Amz-Target", valid_606524
  var valid_606525 = header.getOrDefault("X-Amz-Signature")
  valid_606525 = validateParameter(valid_606525, JString, required = false,
                                 default = nil)
  if valid_606525 != nil:
    section.add "X-Amz-Signature", valid_606525
  var valid_606526 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606526 = validateParameter(valid_606526, JString, required = false,
                                 default = nil)
  if valid_606526 != nil:
    section.add "X-Amz-Content-Sha256", valid_606526
  var valid_606527 = header.getOrDefault("X-Amz-Date")
  valid_606527 = validateParameter(valid_606527, JString, required = false,
                                 default = nil)
  if valid_606527 != nil:
    section.add "X-Amz-Date", valid_606527
  var valid_606528 = header.getOrDefault("X-Amz-Credential")
  valid_606528 = validateParameter(valid_606528, JString, required = false,
                                 default = nil)
  if valid_606528 != nil:
    section.add "X-Amz-Credential", valid_606528
  var valid_606529 = header.getOrDefault("X-Amz-Security-Token")
  valid_606529 = validateParameter(valid_606529, JString, required = false,
                                 default = nil)
  if valid_606529 != nil:
    section.add "X-Amz-Security-Token", valid_606529
  var valid_606530 = header.getOrDefault("X-Amz-Algorithm")
  valid_606530 = validateParameter(valid_606530, JString, required = false,
                                 default = nil)
  if valid_606530 != nil:
    section.add "X-Amz-Algorithm", valid_606530
  var valid_606531 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606531 = validateParameter(valid_606531, JString, required = false,
                                 default = nil)
  if valid_606531 != nil:
    section.add "X-Amz-SignedHeaders", valid_606531
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606533: Call_RemoveTagsFromStream_606521; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes tags from the specified Kinesis data stream. Removed tags are deleted and cannot be recovered after this operation successfully completes.</p> <p>If you specify a tag that does not exist, it is ignored.</p> <p> <a>RemoveTagsFromStream</a> has a limit of five transactions per second per account.</p>
  ## 
  let valid = call_606533.validator(path, query, header, formData, body)
  let scheme = call_606533.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606533.url(scheme.get, call_606533.host, call_606533.base,
                         call_606533.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606533, url, valid)

proc call*(call_606534: Call_RemoveTagsFromStream_606521; body: JsonNode): Recallable =
  ## removeTagsFromStream
  ## <p>Removes tags from the specified Kinesis data stream. Removed tags are deleted and cannot be recovered after this operation successfully completes.</p> <p>If you specify a tag that does not exist, it is ignored.</p> <p> <a>RemoveTagsFromStream</a> has a limit of five transactions per second per account.</p>
  ##   body: JObject (required)
  var body_606535 = newJObject()
  if body != nil:
    body_606535 = body
  result = call_606534.call(nil, nil, nil, nil, body_606535)

var removeTagsFromStream* = Call_RemoveTagsFromStream_606521(
    name: "removeTagsFromStream", meth: HttpMethod.HttpPost,
    host: "kinesis.amazonaws.com",
    route: "/#X-Amz-Target=Kinesis_20131202.RemoveTagsFromStream",
    validator: validate_RemoveTagsFromStream_606522, base: "/",
    url: url_RemoveTagsFromStream_606523, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SplitShard_606536 = ref object of OpenApiRestCall_605589
proc url_SplitShard_606538(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SplitShard_606537(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Splits a shard into two new shards in the Kinesis data stream, to increase the stream's capacity to ingest and transport data. <code>SplitShard</code> is called when there is a need to increase the overall capacity of a stream because of an expected increase in the volume of data records being ingested. </p> <p>You can also use <code>SplitShard</code> when a shard appears to be approaching its maximum utilization; for example, the producers sending data into the specific shard are suddenly sending more than previously anticipated. You can also call <code>SplitShard</code> to increase stream capacity, so that more Kinesis Data Streams applications can simultaneously read data from the stream for real-time processing. </p> <p>You must specify the shard to be split and the new hash key, which is the position in the shard where the shard gets split in two. In many cases, the new hash key might be the average of the beginning and ending hash key, but it can be any hash key value in the range being mapped into the shard. For more information, see <a href="http://docs.aws.amazon.com/kinesis/latest/dev/kinesis-using-sdk-java-resharding-split.html">Split a Shard</a> in the <i>Amazon Kinesis Data Streams Developer Guide</i>.</p> <p>You can use <a>DescribeStream</a> to determine the shard ID and hash key values for the <code>ShardToSplit</code> and <code>NewStartingHashKey</code> parameters that are specified in the <code>SplitShard</code> request.</p> <p> <code>SplitShard</code> is an asynchronous operation. Upon receiving a <code>SplitShard</code> request, Kinesis Data Streams immediately returns a response and sets the stream status to <code>UPDATING</code>. After the operation is completed, Kinesis Data Streams sets the stream status to <code>ACTIVE</code>. Read and write operations continue to work while the stream is in the <code>UPDATING</code> state. </p> <p>You can use <code>DescribeStream</code> to check the status of the stream, which is returned in <code>StreamStatus</code>. If the stream is in the <code>ACTIVE</code> state, you can call <code>SplitShard</code>. If a stream is in <code>CREATING</code> or <code>UPDATING</code> or <code>DELETING</code> states, <code>DescribeStream</code> returns a <code>ResourceInUseException</code>.</p> <p>If the specified stream does not exist, <code>DescribeStream</code> returns a <code>ResourceNotFoundException</code>. If you try to create more shards than are authorized for your account, you receive a <code>LimitExceededException</code>. </p> <p>For the default shard limit for an AWS account, see <a href="http://docs.aws.amazon.com/kinesis/latest/dev/service-sizes-and-limits.html">Kinesis Data Streams Limits</a> in the <i>Amazon Kinesis Data Streams Developer Guide</i>. To increase this limit, <a href="http://docs.aws.amazon.com/general/latest/gr/aws_service_limits.html">contact AWS Support</a>.</p> <p>If you try to operate on too many streams simultaneously using <a>CreateStream</a>, <a>DeleteStream</a>, <a>MergeShards</a>, and/or <a>SplitShard</a>, you receive a <code>LimitExceededException</code>. </p> <p> <code>SplitShard</code> has a limit of five transactions per second per account.</p>
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
  var valid_606539 = header.getOrDefault("X-Amz-Target")
  valid_606539 = validateParameter(valid_606539, JString, required = true, default = newJString(
      "Kinesis_20131202.SplitShard"))
  if valid_606539 != nil:
    section.add "X-Amz-Target", valid_606539
  var valid_606540 = header.getOrDefault("X-Amz-Signature")
  valid_606540 = validateParameter(valid_606540, JString, required = false,
                                 default = nil)
  if valid_606540 != nil:
    section.add "X-Amz-Signature", valid_606540
  var valid_606541 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606541 = validateParameter(valid_606541, JString, required = false,
                                 default = nil)
  if valid_606541 != nil:
    section.add "X-Amz-Content-Sha256", valid_606541
  var valid_606542 = header.getOrDefault("X-Amz-Date")
  valid_606542 = validateParameter(valid_606542, JString, required = false,
                                 default = nil)
  if valid_606542 != nil:
    section.add "X-Amz-Date", valid_606542
  var valid_606543 = header.getOrDefault("X-Amz-Credential")
  valid_606543 = validateParameter(valid_606543, JString, required = false,
                                 default = nil)
  if valid_606543 != nil:
    section.add "X-Amz-Credential", valid_606543
  var valid_606544 = header.getOrDefault("X-Amz-Security-Token")
  valid_606544 = validateParameter(valid_606544, JString, required = false,
                                 default = nil)
  if valid_606544 != nil:
    section.add "X-Amz-Security-Token", valid_606544
  var valid_606545 = header.getOrDefault("X-Amz-Algorithm")
  valid_606545 = validateParameter(valid_606545, JString, required = false,
                                 default = nil)
  if valid_606545 != nil:
    section.add "X-Amz-Algorithm", valid_606545
  var valid_606546 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606546 = validateParameter(valid_606546, JString, required = false,
                                 default = nil)
  if valid_606546 != nil:
    section.add "X-Amz-SignedHeaders", valid_606546
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606548: Call_SplitShard_606536; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Splits a shard into two new shards in the Kinesis data stream, to increase the stream's capacity to ingest and transport data. <code>SplitShard</code> is called when there is a need to increase the overall capacity of a stream because of an expected increase in the volume of data records being ingested. </p> <p>You can also use <code>SplitShard</code> when a shard appears to be approaching its maximum utilization; for example, the producers sending data into the specific shard are suddenly sending more than previously anticipated. You can also call <code>SplitShard</code> to increase stream capacity, so that more Kinesis Data Streams applications can simultaneously read data from the stream for real-time processing. </p> <p>You must specify the shard to be split and the new hash key, which is the position in the shard where the shard gets split in two. In many cases, the new hash key might be the average of the beginning and ending hash key, but it can be any hash key value in the range being mapped into the shard. For more information, see <a href="http://docs.aws.amazon.com/kinesis/latest/dev/kinesis-using-sdk-java-resharding-split.html">Split a Shard</a> in the <i>Amazon Kinesis Data Streams Developer Guide</i>.</p> <p>You can use <a>DescribeStream</a> to determine the shard ID and hash key values for the <code>ShardToSplit</code> and <code>NewStartingHashKey</code> parameters that are specified in the <code>SplitShard</code> request.</p> <p> <code>SplitShard</code> is an asynchronous operation. Upon receiving a <code>SplitShard</code> request, Kinesis Data Streams immediately returns a response and sets the stream status to <code>UPDATING</code>. After the operation is completed, Kinesis Data Streams sets the stream status to <code>ACTIVE</code>. Read and write operations continue to work while the stream is in the <code>UPDATING</code> state. </p> <p>You can use <code>DescribeStream</code> to check the status of the stream, which is returned in <code>StreamStatus</code>. If the stream is in the <code>ACTIVE</code> state, you can call <code>SplitShard</code>. If a stream is in <code>CREATING</code> or <code>UPDATING</code> or <code>DELETING</code> states, <code>DescribeStream</code> returns a <code>ResourceInUseException</code>.</p> <p>If the specified stream does not exist, <code>DescribeStream</code> returns a <code>ResourceNotFoundException</code>. If you try to create more shards than are authorized for your account, you receive a <code>LimitExceededException</code>. </p> <p>For the default shard limit for an AWS account, see <a href="http://docs.aws.amazon.com/kinesis/latest/dev/service-sizes-and-limits.html">Kinesis Data Streams Limits</a> in the <i>Amazon Kinesis Data Streams Developer Guide</i>. To increase this limit, <a href="http://docs.aws.amazon.com/general/latest/gr/aws_service_limits.html">contact AWS Support</a>.</p> <p>If you try to operate on too many streams simultaneously using <a>CreateStream</a>, <a>DeleteStream</a>, <a>MergeShards</a>, and/or <a>SplitShard</a>, you receive a <code>LimitExceededException</code>. </p> <p> <code>SplitShard</code> has a limit of five transactions per second per account.</p>
  ## 
  let valid = call_606548.validator(path, query, header, formData, body)
  let scheme = call_606548.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606548.url(scheme.get, call_606548.host, call_606548.base,
                         call_606548.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606548, url, valid)

proc call*(call_606549: Call_SplitShard_606536; body: JsonNode): Recallable =
  ## splitShard
  ## <p>Splits a shard into two new shards in the Kinesis data stream, to increase the stream's capacity to ingest and transport data. <code>SplitShard</code> is called when there is a need to increase the overall capacity of a stream because of an expected increase in the volume of data records being ingested. </p> <p>You can also use <code>SplitShard</code> when a shard appears to be approaching its maximum utilization; for example, the producers sending data into the specific shard are suddenly sending more than previously anticipated. You can also call <code>SplitShard</code> to increase stream capacity, so that more Kinesis Data Streams applications can simultaneously read data from the stream for real-time processing. </p> <p>You must specify the shard to be split and the new hash key, which is the position in the shard where the shard gets split in two. In many cases, the new hash key might be the average of the beginning and ending hash key, but it can be any hash key value in the range being mapped into the shard. For more information, see <a href="http://docs.aws.amazon.com/kinesis/latest/dev/kinesis-using-sdk-java-resharding-split.html">Split a Shard</a> in the <i>Amazon Kinesis Data Streams Developer Guide</i>.</p> <p>You can use <a>DescribeStream</a> to determine the shard ID and hash key values for the <code>ShardToSplit</code> and <code>NewStartingHashKey</code> parameters that are specified in the <code>SplitShard</code> request.</p> <p> <code>SplitShard</code> is an asynchronous operation. Upon receiving a <code>SplitShard</code> request, Kinesis Data Streams immediately returns a response and sets the stream status to <code>UPDATING</code>. After the operation is completed, Kinesis Data Streams sets the stream status to <code>ACTIVE</code>. Read and write operations continue to work while the stream is in the <code>UPDATING</code> state. </p> <p>You can use <code>DescribeStream</code> to check the status of the stream, which is returned in <code>StreamStatus</code>. If the stream is in the <code>ACTIVE</code> state, you can call <code>SplitShard</code>. If a stream is in <code>CREATING</code> or <code>UPDATING</code> or <code>DELETING</code> states, <code>DescribeStream</code> returns a <code>ResourceInUseException</code>.</p> <p>If the specified stream does not exist, <code>DescribeStream</code> returns a <code>ResourceNotFoundException</code>. If you try to create more shards than are authorized for your account, you receive a <code>LimitExceededException</code>. </p> <p>For the default shard limit for an AWS account, see <a href="http://docs.aws.amazon.com/kinesis/latest/dev/service-sizes-and-limits.html">Kinesis Data Streams Limits</a> in the <i>Amazon Kinesis Data Streams Developer Guide</i>. To increase this limit, <a href="http://docs.aws.amazon.com/general/latest/gr/aws_service_limits.html">contact AWS Support</a>.</p> <p>If you try to operate on too many streams simultaneously using <a>CreateStream</a>, <a>DeleteStream</a>, <a>MergeShards</a>, and/or <a>SplitShard</a>, you receive a <code>LimitExceededException</code>. </p> <p> <code>SplitShard</code> has a limit of five transactions per second per account.</p>
  ##   body: JObject (required)
  var body_606550 = newJObject()
  if body != nil:
    body_606550 = body
  result = call_606549.call(nil, nil, nil, nil, body_606550)

var splitShard* = Call_SplitShard_606536(name: "splitShard",
                                      meth: HttpMethod.HttpPost,
                                      host: "kinesis.amazonaws.com", route: "/#X-Amz-Target=Kinesis_20131202.SplitShard",
                                      validator: validate_SplitShard_606537,
                                      base: "/", url: url_SplitShard_606538,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartStreamEncryption_606551 = ref object of OpenApiRestCall_605589
proc url_StartStreamEncryption_606553(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartStreamEncryption_606552(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Enables or updates server-side encryption using an AWS KMS key for a specified stream. </p> <p>Starting encryption is an asynchronous operation. Upon receiving the request, Kinesis Data Streams returns immediately and sets the status of the stream to <code>UPDATING</code>. After the update is complete, Kinesis Data Streams sets the status of the stream back to <code>ACTIVE</code>. Updating or applying encryption normally takes a few seconds to complete, but it can take minutes. You can continue to read and write data to your stream while its status is <code>UPDATING</code>. Once the status of the stream is <code>ACTIVE</code>, encryption begins for records written to the stream. </p> <p>API Limits: You can successfully apply a new AWS KMS key for server-side encryption 25 times in a rolling 24-hour period.</p> <p>Note: It can take up to 5 seconds after the stream is in an <code>ACTIVE</code> status before all records written to the stream are encrypted. After you enable encryption, you can verify that encryption is applied by inspecting the API response from <code>PutRecord</code> or <code>PutRecords</code>.</p>
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
  var valid_606554 = header.getOrDefault("X-Amz-Target")
  valid_606554 = validateParameter(valid_606554, JString, required = true, default = newJString(
      "Kinesis_20131202.StartStreamEncryption"))
  if valid_606554 != nil:
    section.add "X-Amz-Target", valid_606554
  var valid_606555 = header.getOrDefault("X-Amz-Signature")
  valid_606555 = validateParameter(valid_606555, JString, required = false,
                                 default = nil)
  if valid_606555 != nil:
    section.add "X-Amz-Signature", valid_606555
  var valid_606556 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606556 = validateParameter(valid_606556, JString, required = false,
                                 default = nil)
  if valid_606556 != nil:
    section.add "X-Amz-Content-Sha256", valid_606556
  var valid_606557 = header.getOrDefault("X-Amz-Date")
  valid_606557 = validateParameter(valid_606557, JString, required = false,
                                 default = nil)
  if valid_606557 != nil:
    section.add "X-Amz-Date", valid_606557
  var valid_606558 = header.getOrDefault("X-Amz-Credential")
  valid_606558 = validateParameter(valid_606558, JString, required = false,
                                 default = nil)
  if valid_606558 != nil:
    section.add "X-Amz-Credential", valid_606558
  var valid_606559 = header.getOrDefault("X-Amz-Security-Token")
  valid_606559 = validateParameter(valid_606559, JString, required = false,
                                 default = nil)
  if valid_606559 != nil:
    section.add "X-Amz-Security-Token", valid_606559
  var valid_606560 = header.getOrDefault("X-Amz-Algorithm")
  valid_606560 = validateParameter(valid_606560, JString, required = false,
                                 default = nil)
  if valid_606560 != nil:
    section.add "X-Amz-Algorithm", valid_606560
  var valid_606561 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606561 = validateParameter(valid_606561, JString, required = false,
                                 default = nil)
  if valid_606561 != nil:
    section.add "X-Amz-SignedHeaders", valid_606561
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606563: Call_StartStreamEncryption_606551; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables or updates server-side encryption using an AWS KMS key for a specified stream. </p> <p>Starting encryption is an asynchronous operation. Upon receiving the request, Kinesis Data Streams returns immediately and sets the status of the stream to <code>UPDATING</code>. After the update is complete, Kinesis Data Streams sets the status of the stream back to <code>ACTIVE</code>. Updating or applying encryption normally takes a few seconds to complete, but it can take minutes. You can continue to read and write data to your stream while its status is <code>UPDATING</code>. Once the status of the stream is <code>ACTIVE</code>, encryption begins for records written to the stream. </p> <p>API Limits: You can successfully apply a new AWS KMS key for server-side encryption 25 times in a rolling 24-hour period.</p> <p>Note: It can take up to 5 seconds after the stream is in an <code>ACTIVE</code> status before all records written to the stream are encrypted. After you enable encryption, you can verify that encryption is applied by inspecting the API response from <code>PutRecord</code> or <code>PutRecords</code>.</p>
  ## 
  let valid = call_606563.validator(path, query, header, formData, body)
  let scheme = call_606563.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606563.url(scheme.get, call_606563.host, call_606563.base,
                         call_606563.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606563, url, valid)

proc call*(call_606564: Call_StartStreamEncryption_606551; body: JsonNode): Recallable =
  ## startStreamEncryption
  ## <p>Enables or updates server-side encryption using an AWS KMS key for a specified stream. </p> <p>Starting encryption is an asynchronous operation. Upon receiving the request, Kinesis Data Streams returns immediately and sets the status of the stream to <code>UPDATING</code>. After the update is complete, Kinesis Data Streams sets the status of the stream back to <code>ACTIVE</code>. Updating or applying encryption normally takes a few seconds to complete, but it can take minutes. You can continue to read and write data to your stream while its status is <code>UPDATING</code>. Once the status of the stream is <code>ACTIVE</code>, encryption begins for records written to the stream. </p> <p>API Limits: You can successfully apply a new AWS KMS key for server-side encryption 25 times in a rolling 24-hour period.</p> <p>Note: It can take up to 5 seconds after the stream is in an <code>ACTIVE</code> status before all records written to the stream are encrypted. After you enable encryption, you can verify that encryption is applied by inspecting the API response from <code>PutRecord</code> or <code>PutRecords</code>.</p>
  ##   body: JObject (required)
  var body_606565 = newJObject()
  if body != nil:
    body_606565 = body
  result = call_606564.call(nil, nil, nil, nil, body_606565)

var startStreamEncryption* = Call_StartStreamEncryption_606551(
    name: "startStreamEncryption", meth: HttpMethod.HttpPost,
    host: "kinesis.amazonaws.com",
    route: "/#X-Amz-Target=Kinesis_20131202.StartStreamEncryption",
    validator: validate_StartStreamEncryption_606552, base: "/",
    url: url_StartStreamEncryption_606553, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopStreamEncryption_606566 = ref object of OpenApiRestCall_605589
proc url_StopStreamEncryption_606568(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopStreamEncryption_606567(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Disables server-side encryption for a specified stream. </p> <p>Stopping encryption is an asynchronous operation. Upon receiving the request, Kinesis Data Streams returns immediately and sets the status of the stream to <code>UPDATING</code>. After the update is complete, Kinesis Data Streams sets the status of the stream back to <code>ACTIVE</code>. Stopping encryption normally takes a few seconds to complete, but it can take minutes. You can continue to read and write data to your stream while its status is <code>UPDATING</code>. Once the status of the stream is <code>ACTIVE</code>, records written to the stream are no longer encrypted by Kinesis Data Streams. </p> <p>API Limits: You can successfully disable server-side encryption 25 times in a rolling 24-hour period. </p> <p>Note: It can take up to 5 seconds after the stream is in an <code>ACTIVE</code> status before all records written to the stream are no longer subject to encryption. After you disabled encryption, you can verify that encryption is not applied by inspecting the API response from <code>PutRecord</code> or <code>PutRecords</code>.</p>
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
  var valid_606569 = header.getOrDefault("X-Amz-Target")
  valid_606569 = validateParameter(valid_606569, JString, required = true, default = newJString(
      "Kinesis_20131202.StopStreamEncryption"))
  if valid_606569 != nil:
    section.add "X-Amz-Target", valid_606569
  var valid_606570 = header.getOrDefault("X-Amz-Signature")
  valid_606570 = validateParameter(valid_606570, JString, required = false,
                                 default = nil)
  if valid_606570 != nil:
    section.add "X-Amz-Signature", valid_606570
  var valid_606571 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606571 = validateParameter(valid_606571, JString, required = false,
                                 default = nil)
  if valid_606571 != nil:
    section.add "X-Amz-Content-Sha256", valid_606571
  var valid_606572 = header.getOrDefault("X-Amz-Date")
  valid_606572 = validateParameter(valid_606572, JString, required = false,
                                 default = nil)
  if valid_606572 != nil:
    section.add "X-Amz-Date", valid_606572
  var valid_606573 = header.getOrDefault("X-Amz-Credential")
  valid_606573 = validateParameter(valid_606573, JString, required = false,
                                 default = nil)
  if valid_606573 != nil:
    section.add "X-Amz-Credential", valid_606573
  var valid_606574 = header.getOrDefault("X-Amz-Security-Token")
  valid_606574 = validateParameter(valid_606574, JString, required = false,
                                 default = nil)
  if valid_606574 != nil:
    section.add "X-Amz-Security-Token", valid_606574
  var valid_606575 = header.getOrDefault("X-Amz-Algorithm")
  valid_606575 = validateParameter(valid_606575, JString, required = false,
                                 default = nil)
  if valid_606575 != nil:
    section.add "X-Amz-Algorithm", valid_606575
  var valid_606576 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606576 = validateParameter(valid_606576, JString, required = false,
                                 default = nil)
  if valid_606576 != nil:
    section.add "X-Amz-SignedHeaders", valid_606576
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606578: Call_StopStreamEncryption_606566; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disables server-side encryption for a specified stream. </p> <p>Stopping encryption is an asynchronous operation. Upon receiving the request, Kinesis Data Streams returns immediately and sets the status of the stream to <code>UPDATING</code>. After the update is complete, Kinesis Data Streams sets the status of the stream back to <code>ACTIVE</code>. Stopping encryption normally takes a few seconds to complete, but it can take minutes. You can continue to read and write data to your stream while its status is <code>UPDATING</code>. Once the status of the stream is <code>ACTIVE</code>, records written to the stream are no longer encrypted by Kinesis Data Streams. </p> <p>API Limits: You can successfully disable server-side encryption 25 times in a rolling 24-hour period. </p> <p>Note: It can take up to 5 seconds after the stream is in an <code>ACTIVE</code> status before all records written to the stream are no longer subject to encryption. After you disabled encryption, you can verify that encryption is not applied by inspecting the API response from <code>PutRecord</code> or <code>PutRecords</code>.</p>
  ## 
  let valid = call_606578.validator(path, query, header, formData, body)
  let scheme = call_606578.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606578.url(scheme.get, call_606578.host, call_606578.base,
                         call_606578.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606578, url, valid)

proc call*(call_606579: Call_StopStreamEncryption_606566; body: JsonNode): Recallable =
  ## stopStreamEncryption
  ## <p>Disables server-side encryption for a specified stream. </p> <p>Stopping encryption is an asynchronous operation. Upon receiving the request, Kinesis Data Streams returns immediately and sets the status of the stream to <code>UPDATING</code>. After the update is complete, Kinesis Data Streams sets the status of the stream back to <code>ACTIVE</code>. Stopping encryption normally takes a few seconds to complete, but it can take minutes. You can continue to read and write data to your stream while its status is <code>UPDATING</code>. Once the status of the stream is <code>ACTIVE</code>, records written to the stream are no longer encrypted by Kinesis Data Streams. </p> <p>API Limits: You can successfully disable server-side encryption 25 times in a rolling 24-hour period. </p> <p>Note: It can take up to 5 seconds after the stream is in an <code>ACTIVE</code> status before all records written to the stream are no longer subject to encryption. After you disabled encryption, you can verify that encryption is not applied by inspecting the API response from <code>PutRecord</code> or <code>PutRecords</code>.</p>
  ##   body: JObject (required)
  var body_606580 = newJObject()
  if body != nil:
    body_606580 = body
  result = call_606579.call(nil, nil, nil, nil, body_606580)

var stopStreamEncryption* = Call_StopStreamEncryption_606566(
    name: "stopStreamEncryption", meth: HttpMethod.HttpPost,
    host: "kinesis.amazonaws.com",
    route: "/#X-Amz-Target=Kinesis_20131202.StopStreamEncryption",
    validator: validate_StopStreamEncryption_606567, base: "/",
    url: url_StopStreamEncryption_606568, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateShardCount_606581 = ref object of OpenApiRestCall_605589
proc url_UpdateShardCount_606583(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateShardCount_606582(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Updates the shard count of the specified stream to the specified number of shards.</p> <p>Updating the shard count is an asynchronous operation. Upon receiving the request, Kinesis Data Streams returns immediately and sets the status of the stream to <code>UPDATING</code>. After the update is complete, Kinesis Data Streams sets the status of the stream back to <code>ACTIVE</code>. Depending on the size of the stream, the scaling action could take a few minutes to complete. You can continue to read and write data to your stream while its status is <code>UPDATING</code>.</p> <p>To update the shard count, Kinesis Data Streams performs splits or merges on individual shards. This can cause short-lived shards to be created, in addition to the final shards. We recommend that you double or halve the shard count, as this results in the fewest number of splits or merges.</p> <p>This operation has the following default limits. By default, you cannot do the following:</p> <ul> <li> <p>Scale more than twice per rolling 24-hour period per stream</p> </li> <li> <p>Scale up to more than double your current shard count for a stream</p> </li> <li> <p>Scale down below half your current shard count for a stream</p> </li> <li> <p>Scale up to more than 500 shards in a stream</p> </li> <li> <p>Scale a stream with more than 500 shards down unless the result is less than 500 shards</p> </li> <li> <p>Scale up to more than the shard limit for your account</p> </li> </ul> <p>For the default limits for an AWS account, see <a href="http://docs.aws.amazon.com/kinesis/latest/dev/service-sizes-and-limits.html">Streams Limits</a> in the <i>Amazon Kinesis Data Streams Developer Guide</i>. To request an increase in the call rate limit, the shard limit for this API, or your overall shard limit, use the <a href="https://console.aws.amazon.com/support/v1#/case/create?issueType=service-limit-increase&amp;limitType=service-code-kinesis">limits form</a>.</p>
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
  var valid_606584 = header.getOrDefault("X-Amz-Target")
  valid_606584 = validateParameter(valid_606584, JString, required = true, default = newJString(
      "Kinesis_20131202.UpdateShardCount"))
  if valid_606584 != nil:
    section.add "X-Amz-Target", valid_606584
  var valid_606585 = header.getOrDefault("X-Amz-Signature")
  valid_606585 = validateParameter(valid_606585, JString, required = false,
                                 default = nil)
  if valid_606585 != nil:
    section.add "X-Amz-Signature", valid_606585
  var valid_606586 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606586 = validateParameter(valid_606586, JString, required = false,
                                 default = nil)
  if valid_606586 != nil:
    section.add "X-Amz-Content-Sha256", valid_606586
  var valid_606587 = header.getOrDefault("X-Amz-Date")
  valid_606587 = validateParameter(valid_606587, JString, required = false,
                                 default = nil)
  if valid_606587 != nil:
    section.add "X-Amz-Date", valid_606587
  var valid_606588 = header.getOrDefault("X-Amz-Credential")
  valid_606588 = validateParameter(valid_606588, JString, required = false,
                                 default = nil)
  if valid_606588 != nil:
    section.add "X-Amz-Credential", valid_606588
  var valid_606589 = header.getOrDefault("X-Amz-Security-Token")
  valid_606589 = validateParameter(valid_606589, JString, required = false,
                                 default = nil)
  if valid_606589 != nil:
    section.add "X-Amz-Security-Token", valid_606589
  var valid_606590 = header.getOrDefault("X-Amz-Algorithm")
  valid_606590 = validateParameter(valid_606590, JString, required = false,
                                 default = nil)
  if valid_606590 != nil:
    section.add "X-Amz-Algorithm", valid_606590
  var valid_606591 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606591 = validateParameter(valid_606591, JString, required = false,
                                 default = nil)
  if valid_606591 != nil:
    section.add "X-Amz-SignedHeaders", valid_606591
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606593: Call_UpdateShardCount_606581; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the shard count of the specified stream to the specified number of shards.</p> <p>Updating the shard count is an asynchronous operation. Upon receiving the request, Kinesis Data Streams returns immediately and sets the status of the stream to <code>UPDATING</code>. After the update is complete, Kinesis Data Streams sets the status of the stream back to <code>ACTIVE</code>. Depending on the size of the stream, the scaling action could take a few minutes to complete. You can continue to read and write data to your stream while its status is <code>UPDATING</code>.</p> <p>To update the shard count, Kinesis Data Streams performs splits or merges on individual shards. This can cause short-lived shards to be created, in addition to the final shards. We recommend that you double or halve the shard count, as this results in the fewest number of splits or merges.</p> <p>This operation has the following default limits. By default, you cannot do the following:</p> <ul> <li> <p>Scale more than twice per rolling 24-hour period per stream</p> </li> <li> <p>Scale up to more than double your current shard count for a stream</p> </li> <li> <p>Scale down below half your current shard count for a stream</p> </li> <li> <p>Scale up to more than 500 shards in a stream</p> </li> <li> <p>Scale a stream with more than 500 shards down unless the result is less than 500 shards</p> </li> <li> <p>Scale up to more than the shard limit for your account</p> </li> </ul> <p>For the default limits for an AWS account, see <a href="http://docs.aws.amazon.com/kinesis/latest/dev/service-sizes-and-limits.html">Streams Limits</a> in the <i>Amazon Kinesis Data Streams Developer Guide</i>. To request an increase in the call rate limit, the shard limit for this API, or your overall shard limit, use the <a href="https://console.aws.amazon.com/support/v1#/case/create?issueType=service-limit-increase&amp;limitType=service-code-kinesis">limits form</a>.</p>
  ## 
  let valid = call_606593.validator(path, query, header, formData, body)
  let scheme = call_606593.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606593.url(scheme.get, call_606593.host, call_606593.base,
                         call_606593.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606593, url, valid)

proc call*(call_606594: Call_UpdateShardCount_606581; body: JsonNode): Recallable =
  ## updateShardCount
  ## <p>Updates the shard count of the specified stream to the specified number of shards.</p> <p>Updating the shard count is an asynchronous operation. Upon receiving the request, Kinesis Data Streams returns immediately and sets the status of the stream to <code>UPDATING</code>. After the update is complete, Kinesis Data Streams sets the status of the stream back to <code>ACTIVE</code>. Depending on the size of the stream, the scaling action could take a few minutes to complete. You can continue to read and write data to your stream while its status is <code>UPDATING</code>.</p> <p>To update the shard count, Kinesis Data Streams performs splits or merges on individual shards. This can cause short-lived shards to be created, in addition to the final shards. We recommend that you double or halve the shard count, as this results in the fewest number of splits or merges.</p> <p>This operation has the following default limits. By default, you cannot do the following:</p> <ul> <li> <p>Scale more than twice per rolling 24-hour period per stream</p> </li> <li> <p>Scale up to more than double your current shard count for a stream</p> </li> <li> <p>Scale down below half your current shard count for a stream</p> </li> <li> <p>Scale up to more than 500 shards in a stream</p> </li> <li> <p>Scale a stream with more than 500 shards down unless the result is less than 500 shards</p> </li> <li> <p>Scale up to more than the shard limit for your account</p> </li> </ul> <p>For the default limits for an AWS account, see <a href="http://docs.aws.amazon.com/kinesis/latest/dev/service-sizes-and-limits.html">Streams Limits</a> in the <i>Amazon Kinesis Data Streams Developer Guide</i>. To request an increase in the call rate limit, the shard limit for this API, or your overall shard limit, use the <a href="https://console.aws.amazon.com/support/v1#/case/create?issueType=service-limit-increase&amp;limitType=service-code-kinesis">limits form</a>.</p>
  ##   body: JObject (required)
  var body_606595 = newJObject()
  if body != nil:
    body_606595 = body
  result = call_606594.call(nil, nil, nil, nil, body_606595)

var updateShardCount* = Call_UpdateShardCount_606581(name: "updateShardCount",
    meth: HttpMethod.HttpPost, host: "kinesis.amazonaws.com",
    route: "/#X-Amz-Target=Kinesis_20131202.UpdateShardCount",
    validator: validate_UpdateShardCount_606582, base: "/",
    url: url_UpdateShardCount_606583, schemes: {Scheme.Https, Scheme.Http})
export
  rest

type
  EnvKind = enum
    BakeIntoBinary = "Baking $1 into the binary",
    FetchFromEnv = "Fetch $1 from the environment"
template sloppyConst(via: EnvKind; name: untyped): untyped =
  import
    macros

  const
    name {.strdefine.}: string = case via
    of BakeIntoBinary:
      getEnv(astToStr(name), "")
    of FetchFromEnv:
      ""
  static :
    let msg = block:
      if name == "":
        "Missing $1 in the environment"
      else:
        $via
    warning msg % [astToStr(name)]

sloppyConst FetchFromEnv, AWS_ACCESS_KEY_ID
sloppyConst FetchFromEnv, AWS_SECRET_ACCESS_KEY
sloppyConst BakeIntoBinary, AWS_REGION
sloppyConst FetchFromEnv, AWS_ACCOUNT_ID
proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", AWS_ACCESS_KEY_ID)
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", AWS_SECRET_ACCESS_KEY)
    region = os.getEnv("AWS_REGION", AWS_REGION)
  assert secret != "", "need $AWS_SECRET_ACCESS_KEY in environment"
  assert access != "", "need $AWS_ACCESS_KEY_ID in environment"
  assert region != "", "need $AWS_REGION in environment"
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  ## the hook is a terrible earworm
  var headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
  let
    body = input.getOrDefault("body")
    text = if body == nil:
      "" elif body.kind == JString:
      body.getStr else:
      $body
  if body != nil and body.kind != JString:
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  const
    XAmzSecurityToken = "X-Amz-Security-Token"
  if not headers.hasKey(XAmzSecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[XAmzSecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

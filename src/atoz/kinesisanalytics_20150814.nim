
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Kinesis Analytics
## version: 2015-08-14
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon Kinesis Analytics</fullname> <p> <b>Overview</b> </p> <note> <p>This documentation is for version 1 of the Amazon Kinesis Data Analytics API, which only supports SQL applications. Version 2 of the API supports SQL and Java applications. For more information about version 2, see <a href="/kinesisanalytics/latest/apiv2/Welcome.html">Amazon Kinesis Data Analytics API V2 Documentation</a>.</p> </note> <p>This is the <i>Amazon Kinesis Analytics v1 API Reference</i>. The Amazon Kinesis Analytics Developer Guide provides additional information. </p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/kinesisanalytics/
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

  OpenApiRestCall_602466 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602466](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602466): Option[Scheme] {.used.} =
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
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get)

const
  awsServers = {Scheme.Http: {"ap-northeast-1": "kinesisanalytics.ap-northeast-1.amazonaws.com", "ap-southeast-1": "kinesisanalytics.ap-southeast-1.amazonaws.com", "us-west-2": "kinesisanalytics.us-west-2.amazonaws.com", "eu-west-2": "kinesisanalytics.eu-west-2.amazonaws.com", "ap-northeast-3": "kinesisanalytics.ap-northeast-3.amazonaws.com", "eu-central-1": "kinesisanalytics.eu-central-1.amazonaws.com", "us-east-2": "kinesisanalytics.us-east-2.amazonaws.com", "us-east-1": "kinesisanalytics.us-east-1.amazonaws.com", "cn-northwest-1": "kinesisanalytics.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "kinesisanalytics.ap-south-1.amazonaws.com", "eu-north-1": "kinesisanalytics.eu-north-1.amazonaws.com", "ap-northeast-2": "kinesisanalytics.ap-northeast-2.amazonaws.com", "us-west-1": "kinesisanalytics.us-west-1.amazonaws.com", "us-gov-east-1": "kinesisanalytics.us-gov-east-1.amazonaws.com", "eu-west-3": "kinesisanalytics.eu-west-3.amazonaws.com", "cn-north-1": "kinesisanalytics.cn-north-1.amazonaws.com.cn", "sa-east-1": "kinesisanalytics.sa-east-1.amazonaws.com", "eu-west-1": "kinesisanalytics.eu-west-1.amazonaws.com", "us-gov-west-1": "kinesisanalytics.us-gov-west-1.amazonaws.com", "ap-southeast-2": "kinesisanalytics.ap-southeast-2.amazonaws.com", "ca-central-1": "kinesisanalytics.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "kinesisanalytics.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "kinesisanalytics.ap-southeast-1.amazonaws.com",
      "us-west-2": "kinesisanalytics.us-west-2.amazonaws.com",
      "eu-west-2": "kinesisanalytics.eu-west-2.amazonaws.com",
      "ap-northeast-3": "kinesisanalytics.ap-northeast-3.amazonaws.com",
      "eu-central-1": "kinesisanalytics.eu-central-1.amazonaws.com",
      "us-east-2": "kinesisanalytics.us-east-2.amazonaws.com",
      "us-east-1": "kinesisanalytics.us-east-1.amazonaws.com",
      "cn-northwest-1": "kinesisanalytics.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "kinesisanalytics.ap-south-1.amazonaws.com",
      "eu-north-1": "kinesisanalytics.eu-north-1.amazonaws.com",
      "ap-northeast-2": "kinesisanalytics.ap-northeast-2.amazonaws.com",
      "us-west-1": "kinesisanalytics.us-west-1.amazonaws.com",
      "us-gov-east-1": "kinesisanalytics.us-gov-east-1.amazonaws.com",
      "eu-west-3": "kinesisanalytics.eu-west-3.amazonaws.com",
      "cn-north-1": "kinesisanalytics.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "kinesisanalytics.sa-east-1.amazonaws.com",
      "eu-west-1": "kinesisanalytics.eu-west-1.amazonaws.com",
      "us-gov-west-1": "kinesisanalytics.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "kinesisanalytics.ap-southeast-2.amazonaws.com",
      "ca-central-1": "kinesisanalytics.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "kinesisanalytics"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AddApplicationCloudWatchLoggingOption_602803 = ref object of OpenApiRestCall_602466
proc url_AddApplicationCloudWatchLoggingOption_602805(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AddApplicationCloudWatchLoggingOption_602804(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <note> <p>This documentation is for version 1 of the Amazon Kinesis Data Analytics API, which only supports SQL applications. Version 2 of the API supports SQL and Java applications. For more information about version 2, see <a href="/kinesisanalytics/latest/apiv2/Welcome.html">Amazon Kinesis Data Analytics API V2 Documentation</a>.</p> </note> <p>Adds a CloudWatch log stream to monitor application configuration errors. For more information about using CloudWatch log streams with Amazon Kinesis Analytics applications, see <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/cloudwatch-logs.html">Working with Amazon CloudWatch Logs</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602917 = header.getOrDefault("X-Amz-Date")
  valid_602917 = validateParameter(valid_602917, JString, required = false,
                                 default = nil)
  if valid_602917 != nil:
    section.add "X-Amz-Date", valid_602917
  var valid_602918 = header.getOrDefault("X-Amz-Security-Token")
  valid_602918 = validateParameter(valid_602918, JString, required = false,
                                 default = nil)
  if valid_602918 != nil:
    section.add "X-Amz-Security-Token", valid_602918
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602932 = header.getOrDefault("X-Amz-Target")
  valid_602932 = validateParameter(valid_602932, JString, required = true, default = newJString(
      "KinesisAnalytics_20150814.AddApplicationCloudWatchLoggingOption"))
  if valid_602932 != nil:
    section.add "X-Amz-Target", valid_602932
  var valid_602933 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602933 = validateParameter(valid_602933, JString, required = false,
                                 default = nil)
  if valid_602933 != nil:
    section.add "X-Amz-Content-Sha256", valid_602933
  var valid_602934 = header.getOrDefault("X-Amz-Algorithm")
  valid_602934 = validateParameter(valid_602934, JString, required = false,
                                 default = nil)
  if valid_602934 != nil:
    section.add "X-Amz-Algorithm", valid_602934
  var valid_602935 = header.getOrDefault("X-Amz-Signature")
  valid_602935 = validateParameter(valid_602935, JString, required = false,
                                 default = nil)
  if valid_602935 != nil:
    section.add "X-Amz-Signature", valid_602935
  var valid_602936 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602936 = validateParameter(valid_602936, JString, required = false,
                                 default = nil)
  if valid_602936 != nil:
    section.add "X-Amz-SignedHeaders", valid_602936
  var valid_602937 = header.getOrDefault("X-Amz-Credential")
  valid_602937 = validateParameter(valid_602937, JString, required = false,
                                 default = nil)
  if valid_602937 != nil:
    section.add "X-Amz-Credential", valid_602937
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602961: Call_AddApplicationCloudWatchLoggingOption_602803;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <note> <p>This documentation is for version 1 of the Amazon Kinesis Data Analytics API, which only supports SQL applications. Version 2 of the API supports SQL and Java applications. For more information about version 2, see <a href="/kinesisanalytics/latest/apiv2/Welcome.html">Amazon Kinesis Data Analytics API V2 Documentation</a>.</p> </note> <p>Adds a CloudWatch log stream to monitor application configuration errors. For more information about using CloudWatch log streams with Amazon Kinesis Analytics applications, see <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/cloudwatch-logs.html">Working with Amazon CloudWatch Logs</a>.</p>
  ## 
  let valid = call_602961.validator(path, query, header, formData, body)
  let scheme = call_602961.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602961.url(scheme.get, call_602961.host, call_602961.base,
                         call_602961.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602961, url, valid)

proc call*(call_603032: Call_AddApplicationCloudWatchLoggingOption_602803;
          body: JsonNode): Recallable =
  ## addApplicationCloudWatchLoggingOption
  ## <note> <p>This documentation is for version 1 of the Amazon Kinesis Data Analytics API, which only supports SQL applications. Version 2 of the API supports SQL and Java applications. For more information about version 2, see <a href="/kinesisanalytics/latest/apiv2/Welcome.html">Amazon Kinesis Data Analytics API V2 Documentation</a>.</p> </note> <p>Adds a CloudWatch log stream to monitor application configuration errors. For more information about using CloudWatch log streams with Amazon Kinesis Analytics applications, see <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/cloudwatch-logs.html">Working with Amazon CloudWatch Logs</a>.</p>
  ##   body: JObject (required)
  var body_603033 = newJObject()
  if body != nil:
    body_603033 = body
  result = call_603032.call(nil, nil, nil, nil, body_603033)

var addApplicationCloudWatchLoggingOption* = Call_AddApplicationCloudWatchLoggingOption_602803(
    name: "addApplicationCloudWatchLoggingOption", meth: HttpMethod.HttpPost,
    host: "kinesisanalytics.amazonaws.com", route: "/#X-Amz-Target=KinesisAnalytics_20150814.AddApplicationCloudWatchLoggingOption",
    validator: validate_AddApplicationCloudWatchLoggingOption_602804, base: "/",
    url: url_AddApplicationCloudWatchLoggingOption_602805,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AddApplicationInput_603072 = ref object of OpenApiRestCall_602466
proc url_AddApplicationInput_603074(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AddApplicationInput_603073(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <note> <p>This documentation is for version 1 of the Amazon Kinesis Data Analytics API, which only supports SQL applications. Version 2 of the API supports SQL and Java applications. For more information about version 2, see <a href="/kinesisanalytics/latest/apiv2/Welcome.html">Amazon Kinesis Data Analytics API V2 Documentation</a>.</p> </note> <p> Adds a streaming source to your Amazon Kinesis application. For conceptual information, see <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/how-it-works-input.html">Configuring Application Input</a>. </p> <p>You can add a streaming source either when you create an application or you can use this operation to add a streaming source after you create an application. For more information, see <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/API_CreateApplication.html">CreateApplication</a>.</p> <p>Any configuration update, including adding a streaming source using this operation, results in a new version of the application. You can use the <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/API_DescribeApplication.html">DescribeApplication</a> operation to find the current application version. </p> <p>This operation requires permissions to perform the <code>kinesisanalytics:AddApplicationInput</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603075 = header.getOrDefault("X-Amz-Date")
  valid_603075 = validateParameter(valid_603075, JString, required = false,
                                 default = nil)
  if valid_603075 != nil:
    section.add "X-Amz-Date", valid_603075
  var valid_603076 = header.getOrDefault("X-Amz-Security-Token")
  valid_603076 = validateParameter(valid_603076, JString, required = false,
                                 default = nil)
  if valid_603076 != nil:
    section.add "X-Amz-Security-Token", valid_603076
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603077 = header.getOrDefault("X-Amz-Target")
  valid_603077 = validateParameter(valid_603077, JString, required = true, default = newJString(
      "KinesisAnalytics_20150814.AddApplicationInput"))
  if valid_603077 != nil:
    section.add "X-Amz-Target", valid_603077
  var valid_603078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603078 = validateParameter(valid_603078, JString, required = false,
                                 default = nil)
  if valid_603078 != nil:
    section.add "X-Amz-Content-Sha256", valid_603078
  var valid_603079 = header.getOrDefault("X-Amz-Algorithm")
  valid_603079 = validateParameter(valid_603079, JString, required = false,
                                 default = nil)
  if valid_603079 != nil:
    section.add "X-Amz-Algorithm", valid_603079
  var valid_603080 = header.getOrDefault("X-Amz-Signature")
  valid_603080 = validateParameter(valid_603080, JString, required = false,
                                 default = nil)
  if valid_603080 != nil:
    section.add "X-Amz-Signature", valid_603080
  var valid_603081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603081 = validateParameter(valid_603081, JString, required = false,
                                 default = nil)
  if valid_603081 != nil:
    section.add "X-Amz-SignedHeaders", valid_603081
  var valid_603082 = header.getOrDefault("X-Amz-Credential")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-Credential", valid_603082
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603084: Call_AddApplicationInput_603072; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <note> <p>This documentation is for version 1 of the Amazon Kinesis Data Analytics API, which only supports SQL applications. Version 2 of the API supports SQL and Java applications. For more information about version 2, see <a href="/kinesisanalytics/latest/apiv2/Welcome.html">Amazon Kinesis Data Analytics API V2 Documentation</a>.</p> </note> <p> Adds a streaming source to your Amazon Kinesis application. For conceptual information, see <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/how-it-works-input.html">Configuring Application Input</a>. </p> <p>You can add a streaming source either when you create an application or you can use this operation to add a streaming source after you create an application. For more information, see <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/API_CreateApplication.html">CreateApplication</a>.</p> <p>Any configuration update, including adding a streaming source using this operation, results in a new version of the application. You can use the <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/API_DescribeApplication.html">DescribeApplication</a> operation to find the current application version. </p> <p>This operation requires permissions to perform the <code>kinesisanalytics:AddApplicationInput</code> action.</p>
  ## 
  let valid = call_603084.validator(path, query, header, formData, body)
  let scheme = call_603084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603084.url(scheme.get, call_603084.host, call_603084.base,
                         call_603084.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603084, url, valid)

proc call*(call_603085: Call_AddApplicationInput_603072; body: JsonNode): Recallable =
  ## addApplicationInput
  ## <note> <p>This documentation is for version 1 of the Amazon Kinesis Data Analytics API, which only supports SQL applications. Version 2 of the API supports SQL and Java applications. For more information about version 2, see <a href="/kinesisanalytics/latest/apiv2/Welcome.html">Amazon Kinesis Data Analytics API V2 Documentation</a>.</p> </note> <p> Adds a streaming source to your Amazon Kinesis application. For conceptual information, see <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/how-it-works-input.html">Configuring Application Input</a>. </p> <p>You can add a streaming source either when you create an application or you can use this operation to add a streaming source after you create an application. For more information, see <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/API_CreateApplication.html">CreateApplication</a>.</p> <p>Any configuration update, including adding a streaming source using this operation, results in a new version of the application. You can use the <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/API_DescribeApplication.html">DescribeApplication</a> operation to find the current application version. </p> <p>This operation requires permissions to perform the <code>kinesisanalytics:AddApplicationInput</code> action.</p>
  ##   body: JObject (required)
  var body_603086 = newJObject()
  if body != nil:
    body_603086 = body
  result = call_603085.call(nil, nil, nil, nil, body_603086)

var addApplicationInput* = Call_AddApplicationInput_603072(
    name: "addApplicationInput", meth: HttpMethod.HttpPost,
    host: "kinesisanalytics.amazonaws.com",
    route: "/#X-Amz-Target=KinesisAnalytics_20150814.AddApplicationInput",
    validator: validate_AddApplicationInput_603073, base: "/",
    url: url_AddApplicationInput_603074, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AddApplicationInputProcessingConfiguration_603087 = ref object of OpenApiRestCall_602466
proc url_AddApplicationInputProcessingConfiguration_603089(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AddApplicationInputProcessingConfiguration_603088(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <note> <p>This documentation is for version 1 of the Amazon Kinesis Data Analytics API, which only supports SQL applications. Version 2 of the API supports SQL and Java applications. For more information about version 2, see <a href="/kinesisanalytics/latest/apiv2/Welcome.html">Amazon Kinesis Data Analytics API V2 Documentation</a>.</p> </note> <p>Adds an <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/API_InputProcessingConfiguration.html">InputProcessingConfiguration</a> to an application. An input processor preprocesses records on the input stream before the application's SQL code executes. Currently, the only input processor available is <a href="https://docs.aws.amazon.com/lambda/">AWS Lambda</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603090 = header.getOrDefault("X-Amz-Date")
  valid_603090 = validateParameter(valid_603090, JString, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "X-Amz-Date", valid_603090
  var valid_603091 = header.getOrDefault("X-Amz-Security-Token")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "X-Amz-Security-Token", valid_603091
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603092 = header.getOrDefault("X-Amz-Target")
  valid_603092 = validateParameter(valid_603092, JString, required = true, default = newJString(
      "KinesisAnalytics_20150814.AddApplicationInputProcessingConfiguration"))
  if valid_603092 != nil:
    section.add "X-Amz-Target", valid_603092
  var valid_603093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603093 = validateParameter(valid_603093, JString, required = false,
                                 default = nil)
  if valid_603093 != nil:
    section.add "X-Amz-Content-Sha256", valid_603093
  var valid_603094 = header.getOrDefault("X-Amz-Algorithm")
  valid_603094 = validateParameter(valid_603094, JString, required = false,
                                 default = nil)
  if valid_603094 != nil:
    section.add "X-Amz-Algorithm", valid_603094
  var valid_603095 = header.getOrDefault("X-Amz-Signature")
  valid_603095 = validateParameter(valid_603095, JString, required = false,
                                 default = nil)
  if valid_603095 != nil:
    section.add "X-Amz-Signature", valid_603095
  var valid_603096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603096 = validateParameter(valid_603096, JString, required = false,
                                 default = nil)
  if valid_603096 != nil:
    section.add "X-Amz-SignedHeaders", valid_603096
  var valid_603097 = header.getOrDefault("X-Amz-Credential")
  valid_603097 = validateParameter(valid_603097, JString, required = false,
                                 default = nil)
  if valid_603097 != nil:
    section.add "X-Amz-Credential", valid_603097
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603099: Call_AddApplicationInputProcessingConfiguration_603087;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <note> <p>This documentation is for version 1 of the Amazon Kinesis Data Analytics API, which only supports SQL applications. Version 2 of the API supports SQL and Java applications. For more information about version 2, see <a href="/kinesisanalytics/latest/apiv2/Welcome.html">Amazon Kinesis Data Analytics API V2 Documentation</a>.</p> </note> <p>Adds an <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/API_InputProcessingConfiguration.html">InputProcessingConfiguration</a> to an application. An input processor preprocesses records on the input stream before the application's SQL code executes. Currently, the only input processor available is <a href="https://docs.aws.amazon.com/lambda/">AWS Lambda</a>.</p>
  ## 
  let valid = call_603099.validator(path, query, header, formData, body)
  let scheme = call_603099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603099.url(scheme.get, call_603099.host, call_603099.base,
                         call_603099.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603099, url, valid)

proc call*(call_603100: Call_AddApplicationInputProcessingConfiguration_603087;
          body: JsonNode): Recallable =
  ## addApplicationInputProcessingConfiguration
  ## <note> <p>This documentation is for version 1 of the Amazon Kinesis Data Analytics API, which only supports SQL applications. Version 2 of the API supports SQL and Java applications. For more information about version 2, see <a href="/kinesisanalytics/latest/apiv2/Welcome.html">Amazon Kinesis Data Analytics API V2 Documentation</a>.</p> </note> <p>Adds an <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/API_InputProcessingConfiguration.html">InputProcessingConfiguration</a> to an application. An input processor preprocesses records on the input stream before the application's SQL code executes. Currently, the only input processor available is <a href="https://docs.aws.amazon.com/lambda/">AWS Lambda</a>.</p>
  ##   body: JObject (required)
  var body_603101 = newJObject()
  if body != nil:
    body_603101 = body
  result = call_603100.call(nil, nil, nil, nil, body_603101)

var addApplicationInputProcessingConfiguration* = Call_AddApplicationInputProcessingConfiguration_603087(
    name: "addApplicationInputProcessingConfiguration", meth: HttpMethod.HttpPost,
    host: "kinesisanalytics.amazonaws.com", route: "/#X-Amz-Target=KinesisAnalytics_20150814.AddApplicationInputProcessingConfiguration",
    validator: validate_AddApplicationInputProcessingConfiguration_603088,
    base: "/", url: url_AddApplicationInputProcessingConfiguration_603089,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AddApplicationOutput_603102 = ref object of OpenApiRestCall_602466
proc url_AddApplicationOutput_603104(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AddApplicationOutput_603103(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <note> <p>This documentation is for version 1 of the Amazon Kinesis Data Analytics API, which only supports SQL applications. Version 2 of the API supports SQL and Java applications. For more information about version 2, see <a href="/kinesisanalytics/latest/apiv2/Welcome.html">Amazon Kinesis Data Analytics API V2 Documentation</a>.</p> </note> <p>Adds an external destination to your Amazon Kinesis Analytics application.</p> <p>If you want Amazon Kinesis Analytics to deliver data from an in-application stream within your application to an external destination (such as an Amazon Kinesis stream, an Amazon Kinesis Firehose delivery stream, or an AWS Lambda function), you add the relevant configuration to your application using this operation. You can configure one or more outputs for your application. Each output configuration maps an in-application stream and an external destination.</p> <p> You can use one of the output configurations to deliver data from your in-application error stream to an external destination so that you can analyze the errors. For more information, see <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/how-it-works-output.html">Understanding Application Output (Destination)</a>. </p> <p> Any configuration update, including adding a streaming source using this operation, results in a new version of the application. You can use the <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/API_DescribeApplication.html">DescribeApplication</a> operation to find the current application version.</p> <p>For the limits on the number of application inputs and outputs you can configure, see <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/limits.html">Limits</a>.</p> <p>This operation requires permissions to perform the <code>kinesisanalytics:AddApplicationOutput</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603105 = header.getOrDefault("X-Amz-Date")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-Date", valid_603105
  var valid_603106 = header.getOrDefault("X-Amz-Security-Token")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "X-Amz-Security-Token", valid_603106
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603107 = header.getOrDefault("X-Amz-Target")
  valid_603107 = validateParameter(valid_603107, JString, required = true, default = newJString(
      "KinesisAnalytics_20150814.AddApplicationOutput"))
  if valid_603107 != nil:
    section.add "X-Amz-Target", valid_603107
  var valid_603108 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603108 = validateParameter(valid_603108, JString, required = false,
                                 default = nil)
  if valid_603108 != nil:
    section.add "X-Amz-Content-Sha256", valid_603108
  var valid_603109 = header.getOrDefault("X-Amz-Algorithm")
  valid_603109 = validateParameter(valid_603109, JString, required = false,
                                 default = nil)
  if valid_603109 != nil:
    section.add "X-Amz-Algorithm", valid_603109
  var valid_603110 = header.getOrDefault("X-Amz-Signature")
  valid_603110 = validateParameter(valid_603110, JString, required = false,
                                 default = nil)
  if valid_603110 != nil:
    section.add "X-Amz-Signature", valid_603110
  var valid_603111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603111 = validateParameter(valid_603111, JString, required = false,
                                 default = nil)
  if valid_603111 != nil:
    section.add "X-Amz-SignedHeaders", valid_603111
  var valid_603112 = header.getOrDefault("X-Amz-Credential")
  valid_603112 = validateParameter(valid_603112, JString, required = false,
                                 default = nil)
  if valid_603112 != nil:
    section.add "X-Amz-Credential", valid_603112
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603114: Call_AddApplicationOutput_603102; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <note> <p>This documentation is for version 1 of the Amazon Kinesis Data Analytics API, which only supports SQL applications. Version 2 of the API supports SQL and Java applications. For more information about version 2, see <a href="/kinesisanalytics/latest/apiv2/Welcome.html">Amazon Kinesis Data Analytics API V2 Documentation</a>.</p> </note> <p>Adds an external destination to your Amazon Kinesis Analytics application.</p> <p>If you want Amazon Kinesis Analytics to deliver data from an in-application stream within your application to an external destination (such as an Amazon Kinesis stream, an Amazon Kinesis Firehose delivery stream, or an AWS Lambda function), you add the relevant configuration to your application using this operation. You can configure one or more outputs for your application. Each output configuration maps an in-application stream and an external destination.</p> <p> You can use one of the output configurations to deliver data from your in-application error stream to an external destination so that you can analyze the errors. For more information, see <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/how-it-works-output.html">Understanding Application Output (Destination)</a>. </p> <p> Any configuration update, including adding a streaming source using this operation, results in a new version of the application. You can use the <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/API_DescribeApplication.html">DescribeApplication</a> operation to find the current application version.</p> <p>For the limits on the number of application inputs and outputs you can configure, see <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/limits.html">Limits</a>.</p> <p>This operation requires permissions to perform the <code>kinesisanalytics:AddApplicationOutput</code> action.</p>
  ## 
  let valid = call_603114.validator(path, query, header, formData, body)
  let scheme = call_603114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603114.url(scheme.get, call_603114.host, call_603114.base,
                         call_603114.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603114, url, valid)

proc call*(call_603115: Call_AddApplicationOutput_603102; body: JsonNode): Recallable =
  ## addApplicationOutput
  ## <note> <p>This documentation is for version 1 of the Amazon Kinesis Data Analytics API, which only supports SQL applications. Version 2 of the API supports SQL and Java applications. For more information about version 2, see <a href="/kinesisanalytics/latest/apiv2/Welcome.html">Amazon Kinesis Data Analytics API V2 Documentation</a>.</p> </note> <p>Adds an external destination to your Amazon Kinesis Analytics application.</p> <p>If you want Amazon Kinesis Analytics to deliver data from an in-application stream within your application to an external destination (such as an Amazon Kinesis stream, an Amazon Kinesis Firehose delivery stream, or an AWS Lambda function), you add the relevant configuration to your application using this operation. You can configure one or more outputs for your application. Each output configuration maps an in-application stream and an external destination.</p> <p> You can use one of the output configurations to deliver data from your in-application error stream to an external destination so that you can analyze the errors. For more information, see <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/how-it-works-output.html">Understanding Application Output (Destination)</a>. </p> <p> Any configuration update, including adding a streaming source using this operation, results in a new version of the application. You can use the <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/API_DescribeApplication.html">DescribeApplication</a> operation to find the current application version.</p> <p>For the limits on the number of application inputs and outputs you can configure, see <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/limits.html">Limits</a>.</p> <p>This operation requires permissions to perform the <code>kinesisanalytics:AddApplicationOutput</code> action.</p>
  ##   body: JObject (required)
  var body_603116 = newJObject()
  if body != nil:
    body_603116 = body
  result = call_603115.call(nil, nil, nil, nil, body_603116)

var addApplicationOutput* = Call_AddApplicationOutput_603102(
    name: "addApplicationOutput", meth: HttpMethod.HttpPost,
    host: "kinesisanalytics.amazonaws.com",
    route: "/#X-Amz-Target=KinesisAnalytics_20150814.AddApplicationOutput",
    validator: validate_AddApplicationOutput_603103, base: "/",
    url: url_AddApplicationOutput_603104, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AddApplicationReferenceDataSource_603117 = ref object of OpenApiRestCall_602466
proc url_AddApplicationReferenceDataSource_603119(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AddApplicationReferenceDataSource_603118(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <note> <p>This documentation is for version 1 of the Amazon Kinesis Data Analytics API, which only supports SQL applications. Version 2 of the API supports SQL and Java applications. For more information about version 2, see <a href="/kinesisanalytics/latest/apiv2/Welcome.html">Amazon Kinesis Data Analytics API V2 Documentation</a>.</p> </note> <p>Adds a reference data source to an existing application.</p> <p>Amazon Kinesis Analytics reads reference data (that is, an Amazon S3 object) and creates an in-application table within your application. In the request, you provide the source (S3 bucket name and object key name), name of the in-application table to create, and the necessary mapping information that describes how data in Amazon S3 object maps to columns in the resulting in-application table.</p> <p> For conceptual information, see <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/how-it-works-input.html">Configuring Application Input</a>. For the limits on data sources you can add to your application, see <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/limits.html">Limits</a>. </p> <p> This operation requires permissions to perform the <code>kinesisanalytics:AddApplicationOutput</code> action. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603120 = header.getOrDefault("X-Amz-Date")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "X-Amz-Date", valid_603120
  var valid_603121 = header.getOrDefault("X-Amz-Security-Token")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-Security-Token", valid_603121
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603122 = header.getOrDefault("X-Amz-Target")
  valid_603122 = validateParameter(valid_603122, JString, required = true, default = newJString(
      "KinesisAnalytics_20150814.AddApplicationReferenceDataSource"))
  if valid_603122 != nil:
    section.add "X-Amz-Target", valid_603122
  var valid_603123 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603123 = validateParameter(valid_603123, JString, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "X-Amz-Content-Sha256", valid_603123
  var valid_603124 = header.getOrDefault("X-Amz-Algorithm")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "X-Amz-Algorithm", valid_603124
  var valid_603125 = header.getOrDefault("X-Amz-Signature")
  valid_603125 = validateParameter(valid_603125, JString, required = false,
                                 default = nil)
  if valid_603125 != nil:
    section.add "X-Amz-Signature", valid_603125
  var valid_603126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603126 = validateParameter(valid_603126, JString, required = false,
                                 default = nil)
  if valid_603126 != nil:
    section.add "X-Amz-SignedHeaders", valid_603126
  var valid_603127 = header.getOrDefault("X-Amz-Credential")
  valid_603127 = validateParameter(valid_603127, JString, required = false,
                                 default = nil)
  if valid_603127 != nil:
    section.add "X-Amz-Credential", valid_603127
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603129: Call_AddApplicationReferenceDataSource_603117;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <note> <p>This documentation is for version 1 of the Amazon Kinesis Data Analytics API, which only supports SQL applications. Version 2 of the API supports SQL and Java applications. For more information about version 2, see <a href="/kinesisanalytics/latest/apiv2/Welcome.html">Amazon Kinesis Data Analytics API V2 Documentation</a>.</p> </note> <p>Adds a reference data source to an existing application.</p> <p>Amazon Kinesis Analytics reads reference data (that is, an Amazon S3 object) and creates an in-application table within your application. In the request, you provide the source (S3 bucket name and object key name), name of the in-application table to create, and the necessary mapping information that describes how data in Amazon S3 object maps to columns in the resulting in-application table.</p> <p> For conceptual information, see <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/how-it-works-input.html">Configuring Application Input</a>. For the limits on data sources you can add to your application, see <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/limits.html">Limits</a>. </p> <p> This operation requires permissions to perform the <code>kinesisanalytics:AddApplicationOutput</code> action. </p>
  ## 
  let valid = call_603129.validator(path, query, header, formData, body)
  let scheme = call_603129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603129.url(scheme.get, call_603129.host, call_603129.base,
                         call_603129.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603129, url, valid)

proc call*(call_603130: Call_AddApplicationReferenceDataSource_603117;
          body: JsonNode): Recallable =
  ## addApplicationReferenceDataSource
  ## <note> <p>This documentation is for version 1 of the Amazon Kinesis Data Analytics API, which only supports SQL applications. Version 2 of the API supports SQL and Java applications. For more information about version 2, see <a href="/kinesisanalytics/latest/apiv2/Welcome.html">Amazon Kinesis Data Analytics API V2 Documentation</a>.</p> </note> <p>Adds a reference data source to an existing application.</p> <p>Amazon Kinesis Analytics reads reference data (that is, an Amazon S3 object) and creates an in-application table within your application. In the request, you provide the source (S3 bucket name and object key name), name of the in-application table to create, and the necessary mapping information that describes how data in Amazon S3 object maps to columns in the resulting in-application table.</p> <p> For conceptual information, see <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/how-it-works-input.html">Configuring Application Input</a>. For the limits on data sources you can add to your application, see <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/limits.html">Limits</a>. </p> <p> This operation requires permissions to perform the <code>kinesisanalytics:AddApplicationOutput</code> action. </p>
  ##   body: JObject (required)
  var body_603131 = newJObject()
  if body != nil:
    body_603131 = body
  result = call_603130.call(nil, nil, nil, nil, body_603131)

var addApplicationReferenceDataSource* = Call_AddApplicationReferenceDataSource_603117(
    name: "addApplicationReferenceDataSource", meth: HttpMethod.HttpPost,
    host: "kinesisanalytics.amazonaws.com", route: "/#X-Amz-Target=KinesisAnalytics_20150814.AddApplicationReferenceDataSource",
    validator: validate_AddApplicationReferenceDataSource_603118, base: "/",
    url: url_AddApplicationReferenceDataSource_603119,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateApplication_603132 = ref object of OpenApiRestCall_602466
proc url_CreateApplication_603134(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateApplication_603133(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <note> <p>This documentation is for version 1 of the Amazon Kinesis Data Analytics API, which only supports SQL applications. Version 2 of the API supports SQL and Java applications. For more information about version 2, see <a href="/kinesisanalytics/latest/apiv2/Welcome.html">Amazon Kinesis Data Analytics API V2 Documentation</a>.</p> </note> <p> Creates an Amazon Kinesis Analytics application. You can configure each application with one streaming source as input, application code to process the input, and up to three destinations where you want Amazon Kinesis Analytics to write the output data from your application. For an overview, see <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/how-it-works.html">How it Works</a>. </p> <p>In the input configuration, you map the streaming source to an in-application stream, which you can think of as a constantly updating table. In the mapping, you must provide a schema for the in-application stream and map each data column in the in-application stream to a data element in the streaming source.</p> <p>Your application code is one or more SQL statements that read input data, transform it, and generate output. Your application code can create one or more SQL artifacts like SQL streams or pumps.</p> <p>In the output configuration, you can configure the application to write data from in-application streams created in your applications to up to three destinations.</p> <p> To read data from your source stream or write data to destination streams, Amazon Kinesis Analytics needs your permissions. You grant these permissions by creating IAM roles. This operation requires permissions to perform the <code>kinesisanalytics:CreateApplication</code> action. </p> <p> For introductory exercises to create an Amazon Kinesis Analytics application, see <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/getting-started.html">Getting Started</a>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603135 = header.getOrDefault("X-Amz-Date")
  valid_603135 = validateParameter(valid_603135, JString, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "X-Amz-Date", valid_603135
  var valid_603136 = header.getOrDefault("X-Amz-Security-Token")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "X-Amz-Security-Token", valid_603136
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603137 = header.getOrDefault("X-Amz-Target")
  valid_603137 = validateParameter(valid_603137, JString, required = true, default = newJString(
      "KinesisAnalytics_20150814.CreateApplication"))
  if valid_603137 != nil:
    section.add "X-Amz-Target", valid_603137
  var valid_603138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-Content-Sha256", valid_603138
  var valid_603139 = header.getOrDefault("X-Amz-Algorithm")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-Algorithm", valid_603139
  var valid_603140 = header.getOrDefault("X-Amz-Signature")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "X-Amz-Signature", valid_603140
  var valid_603141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603141 = validateParameter(valid_603141, JString, required = false,
                                 default = nil)
  if valid_603141 != nil:
    section.add "X-Amz-SignedHeaders", valid_603141
  var valid_603142 = header.getOrDefault("X-Amz-Credential")
  valid_603142 = validateParameter(valid_603142, JString, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "X-Amz-Credential", valid_603142
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603144: Call_CreateApplication_603132; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <note> <p>This documentation is for version 1 of the Amazon Kinesis Data Analytics API, which only supports SQL applications. Version 2 of the API supports SQL and Java applications. For more information about version 2, see <a href="/kinesisanalytics/latest/apiv2/Welcome.html">Amazon Kinesis Data Analytics API V2 Documentation</a>.</p> </note> <p> Creates an Amazon Kinesis Analytics application. You can configure each application with one streaming source as input, application code to process the input, and up to three destinations where you want Amazon Kinesis Analytics to write the output data from your application. For an overview, see <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/how-it-works.html">How it Works</a>. </p> <p>In the input configuration, you map the streaming source to an in-application stream, which you can think of as a constantly updating table. In the mapping, you must provide a schema for the in-application stream and map each data column in the in-application stream to a data element in the streaming source.</p> <p>Your application code is one or more SQL statements that read input data, transform it, and generate output. Your application code can create one or more SQL artifacts like SQL streams or pumps.</p> <p>In the output configuration, you can configure the application to write data from in-application streams created in your applications to up to three destinations.</p> <p> To read data from your source stream or write data to destination streams, Amazon Kinesis Analytics needs your permissions. You grant these permissions by creating IAM roles. This operation requires permissions to perform the <code>kinesisanalytics:CreateApplication</code> action. </p> <p> For introductory exercises to create an Amazon Kinesis Analytics application, see <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/getting-started.html">Getting Started</a>. </p>
  ## 
  let valid = call_603144.validator(path, query, header, formData, body)
  let scheme = call_603144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603144.url(scheme.get, call_603144.host, call_603144.base,
                         call_603144.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603144, url, valid)

proc call*(call_603145: Call_CreateApplication_603132; body: JsonNode): Recallable =
  ## createApplication
  ## <note> <p>This documentation is for version 1 of the Amazon Kinesis Data Analytics API, which only supports SQL applications. Version 2 of the API supports SQL and Java applications. For more information about version 2, see <a href="/kinesisanalytics/latest/apiv2/Welcome.html">Amazon Kinesis Data Analytics API V2 Documentation</a>.</p> </note> <p> Creates an Amazon Kinesis Analytics application. You can configure each application with one streaming source as input, application code to process the input, and up to three destinations where you want Amazon Kinesis Analytics to write the output data from your application. For an overview, see <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/how-it-works.html">How it Works</a>. </p> <p>In the input configuration, you map the streaming source to an in-application stream, which you can think of as a constantly updating table. In the mapping, you must provide a schema for the in-application stream and map each data column in the in-application stream to a data element in the streaming source.</p> <p>Your application code is one or more SQL statements that read input data, transform it, and generate output. Your application code can create one or more SQL artifacts like SQL streams or pumps.</p> <p>In the output configuration, you can configure the application to write data from in-application streams created in your applications to up to three destinations.</p> <p> To read data from your source stream or write data to destination streams, Amazon Kinesis Analytics needs your permissions. You grant these permissions by creating IAM roles. This operation requires permissions to perform the <code>kinesisanalytics:CreateApplication</code> action. </p> <p> For introductory exercises to create an Amazon Kinesis Analytics application, see <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/getting-started.html">Getting Started</a>. </p>
  ##   body: JObject (required)
  var body_603146 = newJObject()
  if body != nil:
    body_603146 = body
  result = call_603145.call(nil, nil, nil, nil, body_603146)

var createApplication* = Call_CreateApplication_603132(name: "createApplication",
    meth: HttpMethod.HttpPost, host: "kinesisanalytics.amazonaws.com",
    route: "/#X-Amz-Target=KinesisAnalytics_20150814.CreateApplication",
    validator: validate_CreateApplication_603133, base: "/",
    url: url_CreateApplication_603134, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApplication_603147 = ref object of OpenApiRestCall_602466
proc url_DeleteApplication_603149(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteApplication_603148(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <note> <p>This documentation is for version 1 of the Amazon Kinesis Data Analytics API, which only supports SQL applications. Version 2 of the API supports SQL and Java applications. For more information about version 2, see <a href="/kinesisanalytics/latest/apiv2/Welcome.html">Amazon Kinesis Data Analytics API V2 Documentation</a>.</p> </note> <p>Deletes the specified application. Amazon Kinesis Analytics halts application execution and deletes the application, including any application artifacts (such as in-application streams, reference table, and application code).</p> <p>This operation requires permissions to perform the <code>kinesisanalytics:DeleteApplication</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603150 = header.getOrDefault("X-Amz-Date")
  valid_603150 = validateParameter(valid_603150, JString, required = false,
                                 default = nil)
  if valid_603150 != nil:
    section.add "X-Amz-Date", valid_603150
  var valid_603151 = header.getOrDefault("X-Amz-Security-Token")
  valid_603151 = validateParameter(valid_603151, JString, required = false,
                                 default = nil)
  if valid_603151 != nil:
    section.add "X-Amz-Security-Token", valid_603151
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603152 = header.getOrDefault("X-Amz-Target")
  valid_603152 = validateParameter(valid_603152, JString, required = true, default = newJString(
      "KinesisAnalytics_20150814.DeleteApplication"))
  if valid_603152 != nil:
    section.add "X-Amz-Target", valid_603152
  var valid_603153 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "X-Amz-Content-Sha256", valid_603153
  var valid_603154 = header.getOrDefault("X-Amz-Algorithm")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "X-Amz-Algorithm", valid_603154
  var valid_603155 = header.getOrDefault("X-Amz-Signature")
  valid_603155 = validateParameter(valid_603155, JString, required = false,
                                 default = nil)
  if valid_603155 != nil:
    section.add "X-Amz-Signature", valid_603155
  var valid_603156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603156 = validateParameter(valid_603156, JString, required = false,
                                 default = nil)
  if valid_603156 != nil:
    section.add "X-Amz-SignedHeaders", valid_603156
  var valid_603157 = header.getOrDefault("X-Amz-Credential")
  valid_603157 = validateParameter(valid_603157, JString, required = false,
                                 default = nil)
  if valid_603157 != nil:
    section.add "X-Amz-Credential", valid_603157
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603159: Call_DeleteApplication_603147; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <note> <p>This documentation is for version 1 of the Amazon Kinesis Data Analytics API, which only supports SQL applications. Version 2 of the API supports SQL and Java applications. For more information about version 2, see <a href="/kinesisanalytics/latest/apiv2/Welcome.html">Amazon Kinesis Data Analytics API V2 Documentation</a>.</p> </note> <p>Deletes the specified application. Amazon Kinesis Analytics halts application execution and deletes the application, including any application artifacts (such as in-application streams, reference table, and application code).</p> <p>This operation requires permissions to perform the <code>kinesisanalytics:DeleteApplication</code> action.</p>
  ## 
  let valid = call_603159.validator(path, query, header, formData, body)
  let scheme = call_603159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603159.url(scheme.get, call_603159.host, call_603159.base,
                         call_603159.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603159, url, valid)

proc call*(call_603160: Call_DeleteApplication_603147; body: JsonNode): Recallable =
  ## deleteApplication
  ## <note> <p>This documentation is for version 1 of the Amazon Kinesis Data Analytics API, which only supports SQL applications. Version 2 of the API supports SQL and Java applications. For more information about version 2, see <a href="/kinesisanalytics/latest/apiv2/Welcome.html">Amazon Kinesis Data Analytics API V2 Documentation</a>.</p> </note> <p>Deletes the specified application. Amazon Kinesis Analytics halts application execution and deletes the application, including any application artifacts (such as in-application streams, reference table, and application code).</p> <p>This operation requires permissions to perform the <code>kinesisanalytics:DeleteApplication</code> action.</p>
  ##   body: JObject (required)
  var body_603161 = newJObject()
  if body != nil:
    body_603161 = body
  result = call_603160.call(nil, nil, nil, nil, body_603161)

var deleteApplication* = Call_DeleteApplication_603147(name: "deleteApplication",
    meth: HttpMethod.HttpPost, host: "kinesisanalytics.amazonaws.com",
    route: "/#X-Amz-Target=KinesisAnalytics_20150814.DeleteApplication",
    validator: validate_DeleteApplication_603148, base: "/",
    url: url_DeleteApplication_603149, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApplicationCloudWatchLoggingOption_603162 = ref object of OpenApiRestCall_602466
proc url_DeleteApplicationCloudWatchLoggingOption_603164(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteApplicationCloudWatchLoggingOption_603163(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <note> <p>This documentation is for version 1 of the Amazon Kinesis Data Analytics API, which only supports SQL applications. Version 2 of the API supports SQL and Java applications. For more information about version 2, see <a href="/kinesisanalytics/latest/apiv2/Welcome.html">Amazon Kinesis Data Analytics API V2 Documentation</a>.</p> </note> <p>Deletes a CloudWatch log stream from an application. For more information about using CloudWatch log streams with Amazon Kinesis Analytics applications, see <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/cloudwatch-logs.html">Working with Amazon CloudWatch Logs</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603165 = header.getOrDefault("X-Amz-Date")
  valid_603165 = validateParameter(valid_603165, JString, required = false,
                                 default = nil)
  if valid_603165 != nil:
    section.add "X-Amz-Date", valid_603165
  var valid_603166 = header.getOrDefault("X-Amz-Security-Token")
  valid_603166 = validateParameter(valid_603166, JString, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "X-Amz-Security-Token", valid_603166
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603167 = header.getOrDefault("X-Amz-Target")
  valid_603167 = validateParameter(valid_603167, JString, required = true, default = newJString(
      "KinesisAnalytics_20150814.DeleteApplicationCloudWatchLoggingOption"))
  if valid_603167 != nil:
    section.add "X-Amz-Target", valid_603167
  var valid_603168 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603168 = validateParameter(valid_603168, JString, required = false,
                                 default = nil)
  if valid_603168 != nil:
    section.add "X-Amz-Content-Sha256", valid_603168
  var valid_603169 = header.getOrDefault("X-Amz-Algorithm")
  valid_603169 = validateParameter(valid_603169, JString, required = false,
                                 default = nil)
  if valid_603169 != nil:
    section.add "X-Amz-Algorithm", valid_603169
  var valid_603170 = header.getOrDefault("X-Amz-Signature")
  valid_603170 = validateParameter(valid_603170, JString, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "X-Amz-Signature", valid_603170
  var valid_603171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603171 = validateParameter(valid_603171, JString, required = false,
                                 default = nil)
  if valid_603171 != nil:
    section.add "X-Amz-SignedHeaders", valid_603171
  var valid_603172 = header.getOrDefault("X-Amz-Credential")
  valid_603172 = validateParameter(valid_603172, JString, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "X-Amz-Credential", valid_603172
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603174: Call_DeleteApplicationCloudWatchLoggingOption_603162;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <note> <p>This documentation is for version 1 of the Amazon Kinesis Data Analytics API, which only supports SQL applications. Version 2 of the API supports SQL and Java applications. For more information about version 2, see <a href="/kinesisanalytics/latest/apiv2/Welcome.html">Amazon Kinesis Data Analytics API V2 Documentation</a>.</p> </note> <p>Deletes a CloudWatch log stream from an application. For more information about using CloudWatch log streams with Amazon Kinesis Analytics applications, see <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/cloudwatch-logs.html">Working with Amazon CloudWatch Logs</a>.</p>
  ## 
  let valid = call_603174.validator(path, query, header, formData, body)
  let scheme = call_603174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603174.url(scheme.get, call_603174.host, call_603174.base,
                         call_603174.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603174, url, valid)

proc call*(call_603175: Call_DeleteApplicationCloudWatchLoggingOption_603162;
          body: JsonNode): Recallable =
  ## deleteApplicationCloudWatchLoggingOption
  ## <note> <p>This documentation is for version 1 of the Amazon Kinesis Data Analytics API, which only supports SQL applications. Version 2 of the API supports SQL and Java applications. For more information about version 2, see <a href="/kinesisanalytics/latest/apiv2/Welcome.html">Amazon Kinesis Data Analytics API V2 Documentation</a>.</p> </note> <p>Deletes a CloudWatch log stream from an application. For more information about using CloudWatch log streams with Amazon Kinesis Analytics applications, see <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/cloudwatch-logs.html">Working with Amazon CloudWatch Logs</a>.</p>
  ##   body: JObject (required)
  var body_603176 = newJObject()
  if body != nil:
    body_603176 = body
  result = call_603175.call(nil, nil, nil, nil, body_603176)

var deleteApplicationCloudWatchLoggingOption* = Call_DeleteApplicationCloudWatchLoggingOption_603162(
    name: "deleteApplicationCloudWatchLoggingOption", meth: HttpMethod.HttpPost,
    host: "kinesisanalytics.amazonaws.com", route: "/#X-Amz-Target=KinesisAnalytics_20150814.DeleteApplicationCloudWatchLoggingOption",
    validator: validate_DeleteApplicationCloudWatchLoggingOption_603163,
    base: "/", url: url_DeleteApplicationCloudWatchLoggingOption_603164,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApplicationInputProcessingConfiguration_603177 = ref object of OpenApiRestCall_602466
proc url_DeleteApplicationInputProcessingConfiguration_603179(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteApplicationInputProcessingConfiguration_603178(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode): JsonNode =
  ## <note> <p>This documentation is for version 1 of the Amazon Kinesis Data Analytics API, which only supports SQL applications. Version 2 of the API supports SQL and Java applications. For more information about version 2, see <a href="/kinesisanalytics/latest/apiv2/Welcome.html">Amazon Kinesis Data Analytics API V2 Documentation</a>.</p> </note> <p>Deletes an <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/API_InputProcessingConfiguration.html">InputProcessingConfiguration</a> from an input.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603180 = header.getOrDefault("X-Amz-Date")
  valid_603180 = validateParameter(valid_603180, JString, required = false,
                                 default = nil)
  if valid_603180 != nil:
    section.add "X-Amz-Date", valid_603180
  var valid_603181 = header.getOrDefault("X-Amz-Security-Token")
  valid_603181 = validateParameter(valid_603181, JString, required = false,
                                 default = nil)
  if valid_603181 != nil:
    section.add "X-Amz-Security-Token", valid_603181
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603182 = header.getOrDefault("X-Amz-Target")
  valid_603182 = validateParameter(valid_603182, JString, required = true, default = newJString(
      "KinesisAnalytics_20150814.DeleteApplicationInputProcessingConfiguration"))
  if valid_603182 != nil:
    section.add "X-Amz-Target", valid_603182
  var valid_603183 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603183 = validateParameter(valid_603183, JString, required = false,
                                 default = nil)
  if valid_603183 != nil:
    section.add "X-Amz-Content-Sha256", valid_603183
  var valid_603184 = header.getOrDefault("X-Amz-Algorithm")
  valid_603184 = validateParameter(valid_603184, JString, required = false,
                                 default = nil)
  if valid_603184 != nil:
    section.add "X-Amz-Algorithm", valid_603184
  var valid_603185 = header.getOrDefault("X-Amz-Signature")
  valid_603185 = validateParameter(valid_603185, JString, required = false,
                                 default = nil)
  if valid_603185 != nil:
    section.add "X-Amz-Signature", valid_603185
  var valid_603186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603186 = validateParameter(valid_603186, JString, required = false,
                                 default = nil)
  if valid_603186 != nil:
    section.add "X-Amz-SignedHeaders", valid_603186
  var valid_603187 = header.getOrDefault("X-Amz-Credential")
  valid_603187 = validateParameter(valid_603187, JString, required = false,
                                 default = nil)
  if valid_603187 != nil:
    section.add "X-Amz-Credential", valid_603187
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603189: Call_DeleteApplicationInputProcessingConfiguration_603177;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <note> <p>This documentation is for version 1 of the Amazon Kinesis Data Analytics API, which only supports SQL applications. Version 2 of the API supports SQL and Java applications. For more information about version 2, see <a href="/kinesisanalytics/latest/apiv2/Welcome.html">Amazon Kinesis Data Analytics API V2 Documentation</a>.</p> </note> <p>Deletes an <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/API_InputProcessingConfiguration.html">InputProcessingConfiguration</a> from an input.</p>
  ## 
  let valid = call_603189.validator(path, query, header, formData, body)
  let scheme = call_603189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603189.url(scheme.get, call_603189.host, call_603189.base,
                         call_603189.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603189, url, valid)

proc call*(call_603190: Call_DeleteApplicationInputProcessingConfiguration_603177;
          body: JsonNode): Recallable =
  ## deleteApplicationInputProcessingConfiguration
  ## <note> <p>This documentation is for version 1 of the Amazon Kinesis Data Analytics API, which only supports SQL applications. Version 2 of the API supports SQL and Java applications. For more information about version 2, see <a href="/kinesisanalytics/latest/apiv2/Welcome.html">Amazon Kinesis Data Analytics API V2 Documentation</a>.</p> </note> <p>Deletes an <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/API_InputProcessingConfiguration.html">InputProcessingConfiguration</a> from an input.</p>
  ##   body: JObject (required)
  var body_603191 = newJObject()
  if body != nil:
    body_603191 = body
  result = call_603190.call(nil, nil, nil, nil, body_603191)

var deleteApplicationInputProcessingConfiguration* = Call_DeleteApplicationInputProcessingConfiguration_603177(
    name: "deleteApplicationInputProcessingConfiguration",
    meth: HttpMethod.HttpPost, host: "kinesisanalytics.amazonaws.com", route: "/#X-Amz-Target=KinesisAnalytics_20150814.DeleteApplicationInputProcessingConfiguration",
    validator: validate_DeleteApplicationInputProcessingConfiguration_603178,
    base: "/", url: url_DeleteApplicationInputProcessingConfiguration_603179,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApplicationOutput_603192 = ref object of OpenApiRestCall_602466
proc url_DeleteApplicationOutput_603194(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteApplicationOutput_603193(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <note> <p>This documentation is for version 1 of the Amazon Kinesis Data Analytics API, which only supports SQL applications. Version 2 of the API supports SQL and Java applications. For more information about version 2, see <a href="/kinesisanalytics/latest/apiv2/Welcome.html">Amazon Kinesis Data Analytics API V2 Documentation</a>.</p> </note> <p>Deletes output destination configuration from your application configuration. Amazon Kinesis Analytics will no longer write data from the corresponding in-application stream to the external output destination.</p> <p>This operation requires permissions to perform the <code>kinesisanalytics:DeleteApplicationOutput</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603195 = header.getOrDefault("X-Amz-Date")
  valid_603195 = validateParameter(valid_603195, JString, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "X-Amz-Date", valid_603195
  var valid_603196 = header.getOrDefault("X-Amz-Security-Token")
  valid_603196 = validateParameter(valid_603196, JString, required = false,
                                 default = nil)
  if valid_603196 != nil:
    section.add "X-Amz-Security-Token", valid_603196
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603197 = header.getOrDefault("X-Amz-Target")
  valid_603197 = validateParameter(valid_603197, JString, required = true, default = newJString(
      "KinesisAnalytics_20150814.DeleteApplicationOutput"))
  if valid_603197 != nil:
    section.add "X-Amz-Target", valid_603197
  var valid_603198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603198 = validateParameter(valid_603198, JString, required = false,
                                 default = nil)
  if valid_603198 != nil:
    section.add "X-Amz-Content-Sha256", valid_603198
  var valid_603199 = header.getOrDefault("X-Amz-Algorithm")
  valid_603199 = validateParameter(valid_603199, JString, required = false,
                                 default = nil)
  if valid_603199 != nil:
    section.add "X-Amz-Algorithm", valid_603199
  var valid_603200 = header.getOrDefault("X-Amz-Signature")
  valid_603200 = validateParameter(valid_603200, JString, required = false,
                                 default = nil)
  if valid_603200 != nil:
    section.add "X-Amz-Signature", valid_603200
  var valid_603201 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603201 = validateParameter(valid_603201, JString, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "X-Amz-SignedHeaders", valid_603201
  var valid_603202 = header.getOrDefault("X-Amz-Credential")
  valid_603202 = validateParameter(valid_603202, JString, required = false,
                                 default = nil)
  if valid_603202 != nil:
    section.add "X-Amz-Credential", valid_603202
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603204: Call_DeleteApplicationOutput_603192; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <note> <p>This documentation is for version 1 of the Amazon Kinesis Data Analytics API, which only supports SQL applications. Version 2 of the API supports SQL and Java applications. For more information about version 2, see <a href="/kinesisanalytics/latest/apiv2/Welcome.html">Amazon Kinesis Data Analytics API V2 Documentation</a>.</p> </note> <p>Deletes output destination configuration from your application configuration. Amazon Kinesis Analytics will no longer write data from the corresponding in-application stream to the external output destination.</p> <p>This operation requires permissions to perform the <code>kinesisanalytics:DeleteApplicationOutput</code> action.</p>
  ## 
  let valid = call_603204.validator(path, query, header, formData, body)
  let scheme = call_603204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603204.url(scheme.get, call_603204.host, call_603204.base,
                         call_603204.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603204, url, valid)

proc call*(call_603205: Call_DeleteApplicationOutput_603192; body: JsonNode): Recallable =
  ## deleteApplicationOutput
  ## <note> <p>This documentation is for version 1 of the Amazon Kinesis Data Analytics API, which only supports SQL applications. Version 2 of the API supports SQL and Java applications. For more information about version 2, see <a href="/kinesisanalytics/latest/apiv2/Welcome.html">Amazon Kinesis Data Analytics API V2 Documentation</a>.</p> </note> <p>Deletes output destination configuration from your application configuration. Amazon Kinesis Analytics will no longer write data from the corresponding in-application stream to the external output destination.</p> <p>This operation requires permissions to perform the <code>kinesisanalytics:DeleteApplicationOutput</code> action.</p>
  ##   body: JObject (required)
  var body_603206 = newJObject()
  if body != nil:
    body_603206 = body
  result = call_603205.call(nil, nil, nil, nil, body_603206)

var deleteApplicationOutput* = Call_DeleteApplicationOutput_603192(
    name: "deleteApplicationOutput", meth: HttpMethod.HttpPost,
    host: "kinesisanalytics.amazonaws.com",
    route: "/#X-Amz-Target=KinesisAnalytics_20150814.DeleteApplicationOutput",
    validator: validate_DeleteApplicationOutput_603193, base: "/",
    url: url_DeleteApplicationOutput_603194, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApplicationReferenceDataSource_603207 = ref object of OpenApiRestCall_602466
proc url_DeleteApplicationReferenceDataSource_603209(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteApplicationReferenceDataSource_603208(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <note> <p>This documentation is for version 1 of the Amazon Kinesis Data Analytics API, which only supports SQL applications. Version 2 of the API supports SQL and Java applications. For more information about version 2, see <a href="/kinesisanalytics/latest/apiv2/Welcome.html">Amazon Kinesis Data Analytics API V2 Documentation</a>.</p> </note> <p>Deletes a reference data source configuration from the specified application configuration.</p> <p>If the application is running, Amazon Kinesis Analytics immediately removes the in-application table that you created using the <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/API_AddApplicationReferenceDataSource.html">AddApplicationReferenceDataSource</a> operation. </p> <p>This operation requires permissions to perform the <code>kinesisanalytics.DeleteApplicationReferenceDataSource</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603210 = header.getOrDefault("X-Amz-Date")
  valid_603210 = validateParameter(valid_603210, JString, required = false,
                                 default = nil)
  if valid_603210 != nil:
    section.add "X-Amz-Date", valid_603210
  var valid_603211 = header.getOrDefault("X-Amz-Security-Token")
  valid_603211 = validateParameter(valid_603211, JString, required = false,
                                 default = nil)
  if valid_603211 != nil:
    section.add "X-Amz-Security-Token", valid_603211
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603212 = header.getOrDefault("X-Amz-Target")
  valid_603212 = validateParameter(valid_603212, JString, required = true, default = newJString(
      "KinesisAnalytics_20150814.DeleteApplicationReferenceDataSource"))
  if valid_603212 != nil:
    section.add "X-Amz-Target", valid_603212
  var valid_603213 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603213 = validateParameter(valid_603213, JString, required = false,
                                 default = nil)
  if valid_603213 != nil:
    section.add "X-Amz-Content-Sha256", valid_603213
  var valid_603214 = header.getOrDefault("X-Amz-Algorithm")
  valid_603214 = validateParameter(valid_603214, JString, required = false,
                                 default = nil)
  if valid_603214 != nil:
    section.add "X-Amz-Algorithm", valid_603214
  var valid_603215 = header.getOrDefault("X-Amz-Signature")
  valid_603215 = validateParameter(valid_603215, JString, required = false,
                                 default = nil)
  if valid_603215 != nil:
    section.add "X-Amz-Signature", valid_603215
  var valid_603216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603216 = validateParameter(valid_603216, JString, required = false,
                                 default = nil)
  if valid_603216 != nil:
    section.add "X-Amz-SignedHeaders", valid_603216
  var valid_603217 = header.getOrDefault("X-Amz-Credential")
  valid_603217 = validateParameter(valid_603217, JString, required = false,
                                 default = nil)
  if valid_603217 != nil:
    section.add "X-Amz-Credential", valid_603217
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603219: Call_DeleteApplicationReferenceDataSource_603207;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <note> <p>This documentation is for version 1 of the Amazon Kinesis Data Analytics API, which only supports SQL applications. Version 2 of the API supports SQL and Java applications. For more information about version 2, see <a href="/kinesisanalytics/latest/apiv2/Welcome.html">Amazon Kinesis Data Analytics API V2 Documentation</a>.</p> </note> <p>Deletes a reference data source configuration from the specified application configuration.</p> <p>If the application is running, Amazon Kinesis Analytics immediately removes the in-application table that you created using the <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/API_AddApplicationReferenceDataSource.html">AddApplicationReferenceDataSource</a> operation. </p> <p>This operation requires permissions to perform the <code>kinesisanalytics.DeleteApplicationReferenceDataSource</code> action.</p>
  ## 
  let valid = call_603219.validator(path, query, header, formData, body)
  let scheme = call_603219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603219.url(scheme.get, call_603219.host, call_603219.base,
                         call_603219.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603219, url, valid)

proc call*(call_603220: Call_DeleteApplicationReferenceDataSource_603207;
          body: JsonNode): Recallable =
  ## deleteApplicationReferenceDataSource
  ## <note> <p>This documentation is for version 1 of the Amazon Kinesis Data Analytics API, which only supports SQL applications. Version 2 of the API supports SQL and Java applications. For more information about version 2, see <a href="/kinesisanalytics/latest/apiv2/Welcome.html">Amazon Kinesis Data Analytics API V2 Documentation</a>.</p> </note> <p>Deletes a reference data source configuration from the specified application configuration.</p> <p>If the application is running, Amazon Kinesis Analytics immediately removes the in-application table that you created using the <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/API_AddApplicationReferenceDataSource.html">AddApplicationReferenceDataSource</a> operation. </p> <p>This operation requires permissions to perform the <code>kinesisanalytics.DeleteApplicationReferenceDataSource</code> action.</p>
  ##   body: JObject (required)
  var body_603221 = newJObject()
  if body != nil:
    body_603221 = body
  result = call_603220.call(nil, nil, nil, nil, body_603221)

var deleteApplicationReferenceDataSource* = Call_DeleteApplicationReferenceDataSource_603207(
    name: "deleteApplicationReferenceDataSource", meth: HttpMethod.HttpPost,
    host: "kinesisanalytics.amazonaws.com", route: "/#X-Amz-Target=KinesisAnalytics_20150814.DeleteApplicationReferenceDataSource",
    validator: validate_DeleteApplicationReferenceDataSource_603208, base: "/",
    url: url_DeleteApplicationReferenceDataSource_603209,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeApplication_603222 = ref object of OpenApiRestCall_602466
proc url_DescribeApplication_603224(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeApplication_603223(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <note> <p>This documentation is for version 1 of the Amazon Kinesis Data Analytics API, which only supports SQL applications. Version 2 of the API supports SQL and Java applications. For more information about version 2, see <a href="/kinesisanalytics/latest/apiv2/Welcome.html">Amazon Kinesis Data Analytics API V2 Documentation</a>.</p> </note> <p>Returns information about a specific Amazon Kinesis Analytics application.</p> <p>If you want to retrieve a list of all applications in your account, use the <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/API_ListApplications.html">ListApplications</a> operation.</p> <p>This operation requires permissions to perform the <code>kinesisanalytics:DescribeApplication</code> action. You can use <code>DescribeApplication</code> to get the current application versionId, which you need to call other operations such as <code>Update</code>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603225 = header.getOrDefault("X-Amz-Date")
  valid_603225 = validateParameter(valid_603225, JString, required = false,
                                 default = nil)
  if valid_603225 != nil:
    section.add "X-Amz-Date", valid_603225
  var valid_603226 = header.getOrDefault("X-Amz-Security-Token")
  valid_603226 = validateParameter(valid_603226, JString, required = false,
                                 default = nil)
  if valid_603226 != nil:
    section.add "X-Amz-Security-Token", valid_603226
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603227 = header.getOrDefault("X-Amz-Target")
  valid_603227 = validateParameter(valid_603227, JString, required = true, default = newJString(
      "KinesisAnalytics_20150814.DescribeApplication"))
  if valid_603227 != nil:
    section.add "X-Amz-Target", valid_603227
  var valid_603228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603228 = validateParameter(valid_603228, JString, required = false,
                                 default = nil)
  if valid_603228 != nil:
    section.add "X-Amz-Content-Sha256", valid_603228
  var valid_603229 = header.getOrDefault("X-Amz-Algorithm")
  valid_603229 = validateParameter(valid_603229, JString, required = false,
                                 default = nil)
  if valid_603229 != nil:
    section.add "X-Amz-Algorithm", valid_603229
  var valid_603230 = header.getOrDefault("X-Amz-Signature")
  valid_603230 = validateParameter(valid_603230, JString, required = false,
                                 default = nil)
  if valid_603230 != nil:
    section.add "X-Amz-Signature", valid_603230
  var valid_603231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603231 = validateParameter(valid_603231, JString, required = false,
                                 default = nil)
  if valid_603231 != nil:
    section.add "X-Amz-SignedHeaders", valid_603231
  var valid_603232 = header.getOrDefault("X-Amz-Credential")
  valid_603232 = validateParameter(valid_603232, JString, required = false,
                                 default = nil)
  if valid_603232 != nil:
    section.add "X-Amz-Credential", valid_603232
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603234: Call_DescribeApplication_603222; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <note> <p>This documentation is for version 1 of the Amazon Kinesis Data Analytics API, which only supports SQL applications. Version 2 of the API supports SQL and Java applications. For more information about version 2, see <a href="/kinesisanalytics/latest/apiv2/Welcome.html">Amazon Kinesis Data Analytics API V2 Documentation</a>.</p> </note> <p>Returns information about a specific Amazon Kinesis Analytics application.</p> <p>If you want to retrieve a list of all applications in your account, use the <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/API_ListApplications.html">ListApplications</a> operation.</p> <p>This operation requires permissions to perform the <code>kinesisanalytics:DescribeApplication</code> action. You can use <code>DescribeApplication</code> to get the current application versionId, which you need to call other operations such as <code>Update</code>. </p>
  ## 
  let valid = call_603234.validator(path, query, header, formData, body)
  let scheme = call_603234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603234.url(scheme.get, call_603234.host, call_603234.base,
                         call_603234.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603234, url, valid)

proc call*(call_603235: Call_DescribeApplication_603222; body: JsonNode): Recallable =
  ## describeApplication
  ## <note> <p>This documentation is for version 1 of the Amazon Kinesis Data Analytics API, which only supports SQL applications. Version 2 of the API supports SQL and Java applications. For more information about version 2, see <a href="/kinesisanalytics/latest/apiv2/Welcome.html">Amazon Kinesis Data Analytics API V2 Documentation</a>.</p> </note> <p>Returns information about a specific Amazon Kinesis Analytics application.</p> <p>If you want to retrieve a list of all applications in your account, use the <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/API_ListApplications.html">ListApplications</a> operation.</p> <p>This operation requires permissions to perform the <code>kinesisanalytics:DescribeApplication</code> action. You can use <code>DescribeApplication</code> to get the current application versionId, which you need to call other operations such as <code>Update</code>. </p>
  ##   body: JObject (required)
  var body_603236 = newJObject()
  if body != nil:
    body_603236 = body
  result = call_603235.call(nil, nil, nil, nil, body_603236)

var describeApplication* = Call_DescribeApplication_603222(
    name: "describeApplication", meth: HttpMethod.HttpPost,
    host: "kinesisanalytics.amazonaws.com",
    route: "/#X-Amz-Target=KinesisAnalytics_20150814.DescribeApplication",
    validator: validate_DescribeApplication_603223, base: "/",
    url: url_DescribeApplication_603224, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DiscoverInputSchema_603237 = ref object of OpenApiRestCall_602466
proc url_DiscoverInputSchema_603239(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DiscoverInputSchema_603238(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <note> <p>This documentation is for version 1 of the Amazon Kinesis Data Analytics API, which only supports SQL applications. Version 2 of the API supports SQL and Java applications. For more information about version 2, see <a href="/kinesisanalytics/latest/apiv2/Welcome.html">Amazon Kinesis Data Analytics API V2 Documentation</a>.</p> </note> <p>Infers a schema by evaluating sample records on the specified streaming source (Amazon Kinesis stream or Amazon Kinesis Firehose delivery stream) or S3 object. In the response, the operation returns the inferred schema and also the sample records that the operation used to infer the schema.</p> <p> You can use the inferred schema when configuring a streaming source for your application. For conceptual information, see <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/how-it-works-input.html">Configuring Application Input</a>. Note that when you create an application using the Amazon Kinesis Analytics console, the console uses this operation to infer a schema and show it in the console user interface. </p> <p> This operation requires permissions to perform the <code>kinesisanalytics:DiscoverInputSchema</code> action. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603240 = header.getOrDefault("X-Amz-Date")
  valid_603240 = validateParameter(valid_603240, JString, required = false,
                                 default = nil)
  if valid_603240 != nil:
    section.add "X-Amz-Date", valid_603240
  var valid_603241 = header.getOrDefault("X-Amz-Security-Token")
  valid_603241 = validateParameter(valid_603241, JString, required = false,
                                 default = nil)
  if valid_603241 != nil:
    section.add "X-Amz-Security-Token", valid_603241
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603242 = header.getOrDefault("X-Amz-Target")
  valid_603242 = validateParameter(valid_603242, JString, required = true, default = newJString(
      "KinesisAnalytics_20150814.DiscoverInputSchema"))
  if valid_603242 != nil:
    section.add "X-Amz-Target", valid_603242
  var valid_603243 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603243 = validateParameter(valid_603243, JString, required = false,
                                 default = nil)
  if valid_603243 != nil:
    section.add "X-Amz-Content-Sha256", valid_603243
  var valid_603244 = header.getOrDefault("X-Amz-Algorithm")
  valid_603244 = validateParameter(valid_603244, JString, required = false,
                                 default = nil)
  if valid_603244 != nil:
    section.add "X-Amz-Algorithm", valid_603244
  var valid_603245 = header.getOrDefault("X-Amz-Signature")
  valid_603245 = validateParameter(valid_603245, JString, required = false,
                                 default = nil)
  if valid_603245 != nil:
    section.add "X-Amz-Signature", valid_603245
  var valid_603246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603246 = validateParameter(valid_603246, JString, required = false,
                                 default = nil)
  if valid_603246 != nil:
    section.add "X-Amz-SignedHeaders", valid_603246
  var valid_603247 = header.getOrDefault("X-Amz-Credential")
  valid_603247 = validateParameter(valid_603247, JString, required = false,
                                 default = nil)
  if valid_603247 != nil:
    section.add "X-Amz-Credential", valid_603247
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603249: Call_DiscoverInputSchema_603237; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <note> <p>This documentation is for version 1 of the Amazon Kinesis Data Analytics API, which only supports SQL applications. Version 2 of the API supports SQL and Java applications. For more information about version 2, see <a href="/kinesisanalytics/latest/apiv2/Welcome.html">Amazon Kinesis Data Analytics API V2 Documentation</a>.</p> </note> <p>Infers a schema by evaluating sample records on the specified streaming source (Amazon Kinesis stream or Amazon Kinesis Firehose delivery stream) or S3 object. In the response, the operation returns the inferred schema and also the sample records that the operation used to infer the schema.</p> <p> You can use the inferred schema when configuring a streaming source for your application. For conceptual information, see <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/how-it-works-input.html">Configuring Application Input</a>. Note that when you create an application using the Amazon Kinesis Analytics console, the console uses this operation to infer a schema and show it in the console user interface. </p> <p> This operation requires permissions to perform the <code>kinesisanalytics:DiscoverInputSchema</code> action. </p>
  ## 
  let valid = call_603249.validator(path, query, header, formData, body)
  let scheme = call_603249.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603249.url(scheme.get, call_603249.host, call_603249.base,
                         call_603249.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603249, url, valid)

proc call*(call_603250: Call_DiscoverInputSchema_603237; body: JsonNode): Recallable =
  ## discoverInputSchema
  ## <note> <p>This documentation is for version 1 of the Amazon Kinesis Data Analytics API, which only supports SQL applications. Version 2 of the API supports SQL and Java applications. For more information about version 2, see <a href="/kinesisanalytics/latest/apiv2/Welcome.html">Amazon Kinesis Data Analytics API V2 Documentation</a>.</p> </note> <p>Infers a schema by evaluating sample records on the specified streaming source (Amazon Kinesis stream or Amazon Kinesis Firehose delivery stream) or S3 object. In the response, the operation returns the inferred schema and also the sample records that the operation used to infer the schema.</p> <p> You can use the inferred schema when configuring a streaming source for your application. For conceptual information, see <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/how-it-works-input.html">Configuring Application Input</a>. Note that when you create an application using the Amazon Kinesis Analytics console, the console uses this operation to infer a schema and show it in the console user interface. </p> <p> This operation requires permissions to perform the <code>kinesisanalytics:DiscoverInputSchema</code> action. </p>
  ##   body: JObject (required)
  var body_603251 = newJObject()
  if body != nil:
    body_603251 = body
  result = call_603250.call(nil, nil, nil, nil, body_603251)

var discoverInputSchema* = Call_DiscoverInputSchema_603237(
    name: "discoverInputSchema", meth: HttpMethod.HttpPost,
    host: "kinesisanalytics.amazonaws.com",
    route: "/#X-Amz-Target=KinesisAnalytics_20150814.DiscoverInputSchema",
    validator: validate_DiscoverInputSchema_603238, base: "/",
    url: url_DiscoverInputSchema_603239, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApplications_603252 = ref object of OpenApiRestCall_602466
proc url_ListApplications_603254(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListApplications_603253(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <note> <p>This documentation is for version 1 of the Amazon Kinesis Data Analytics API, which only supports SQL applications. Version 2 of the API supports SQL and Java applications. For more information about version 2, see <a href="/kinesisanalytics/latest/apiv2/Welcome.html">Amazon Kinesis Data Analytics API V2 Documentation</a>.</p> </note> <p>Returns a list of Amazon Kinesis Analytics applications in your account. For each application, the response includes the application name, Amazon Resource Name (ARN), and status. If the response returns the <code>HasMoreApplications</code> value as true, you can send another request by adding the <code>ExclusiveStartApplicationName</code> in the request body, and set the value of this to the last application name from the previous response. </p> <p>If you want detailed information about a specific application, use <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/API_DescribeApplication.html">DescribeApplication</a>.</p> <p>This operation requires permissions to perform the <code>kinesisanalytics:ListApplications</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603255 = header.getOrDefault("X-Amz-Date")
  valid_603255 = validateParameter(valid_603255, JString, required = false,
                                 default = nil)
  if valid_603255 != nil:
    section.add "X-Amz-Date", valid_603255
  var valid_603256 = header.getOrDefault("X-Amz-Security-Token")
  valid_603256 = validateParameter(valid_603256, JString, required = false,
                                 default = nil)
  if valid_603256 != nil:
    section.add "X-Amz-Security-Token", valid_603256
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603257 = header.getOrDefault("X-Amz-Target")
  valid_603257 = validateParameter(valid_603257, JString, required = true, default = newJString(
      "KinesisAnalytics_20150814.ListApplications"))
  if valid_603257 != nil:
    section.add "X-Amz-Target", valid_603257
  var valid_603258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603258 = validateParameter(valid_603258, JString, required = false,
                                 default = nil)
  if valid_603258 != nil:
    section.add "X-Amz-Content-Sha256", valid_603258
  var valid_603259 = header.getOrDefault("X-Amz-Algorithm")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "X-Amz-Algorithm", valid_603259
  var valid_603260 = header.getOrDefault("X-Amz-Signature")
  valid_603260 = validateParameter(valid_603260, JString, required = false,
                                 default = nil)
  if valid_603260 != nil:
    section.add "X-Amz-Signature", valid_603260
  var valid_603261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603261 = validateParameter(valid_603261, JString, required = false,
                                 default = nil)
  if valid_603261 != nil:
    section.add "X-Amz-SignedHeaders", valid_603261
  var valid_603262 = header.getOrDefault("X-Amz-Credential")
  valid_603262 = validateParameter(valid_603262, JString, required = false,
                                 default = nil)
  if valid_603262 != nil:
    section.add "X-Amz-Credential", valid_603262
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603264: Call_ListApplications_603252; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <note> <p>This documentation is for version 1 of the Amazon Kinesis Data Analytics API, which only supports SQL applications. Version 2 of the API supports SQL and Java applications. For more information about version 2, see <a href="/kinesisanalytics/latest/apiv2/Welcome.html">Amazon Kinesis Data Analytics API V2 Documentation</a>.</p> </note> <p>Returns a list of Amazon Kinesis Analytics applications in your account. For each application, the response includes the application name, Amazon Resource Name (ARN), and status. If the response returns the <code>HasMoreApplications</code> value as true, you can send another request by adding the <code>ExclusiveStartApplicationName</code> in the request body, and set the value of this to the last application name from the previous response. </p> <p>If you want detailed information about a specific application, use <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/API_DescribeApplication.html">DescribeApplication</a>.</p> <p>This operation requires permissions to perform the <code>kinesisanalytics:ListApplications</code> action.</p>
  ## 
  let valid = call_603264.validator(path, query, header, formData, body)
  let scheme = call_603264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603264.url(scheme.get, call_603264.host, call_603264.base,
                         call_603264.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603264, url, valid)

proc call*(call_603265: Call_ListApplications_603252; body: JsonNode): Recallable =
  ## listApplications
  ## <note> <p>This documentation is for version 1 of the Amazon Kinesis Data Analytics API, which only supports SQL applications. Version 2 of the API supports SQL and Java applications. For more information about version 2, see <a href="/kinesisanalytics/latest/apiv2/Welcome.html">Amazon Kinesis Data Analytics API V2 Documentation</a>.</p> </note> <p>Returns a list of Amazon Kinesis Analytics applications in your account. For each application, the response includes the application name, Amazon Resource Name (ARN), and status. If the response returns the <code>HasMoreApplications</code> value as true, you can send another request by adding the <code>ExclusiveStartApplicationName</code> in the request body, and set the value of this to the last application name from the previous response. </p> <p>If you want detailed information about a specific application, use <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/API_DescribeApplication.html">DescribeApplication</a>.</p> <p>This operation requires permissions to perform the <code>kinesisanalytics:ListApplications</code> action.</p>
  ##   body: JObject (required)
  var body_603266 = newJObject()
  if body != nil:
    body_603266 = body
  result = call_603265.call(nil, nil, nil, nil, body_603266)

var listApplications* = Call_ListApplications_603252(name: "listApplications",
    meth: HttpMethod.HttpPost, host: "kinesisanalytics.amazonaws.com",
    route: "/#X-Amz-Target=KinesisAnalytics_20150814.ListApplications",
    validator: validate_ListApplications_603253, base: "/",
    url: url_ListApplications_603254, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_603267 = ref object of OpenApiRestCall_602466
proc url_ListTagsForResource_603269(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTagsForResource_603268(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Retrieves the list of key-value tags assigned to the application. For more information, see <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/how-tagging.html">Using Tagging</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603270 = header.getOrDefault("X-Amz-Date")
  valid_603270 = validateParameter(valid_603270, JString, required = false,
                                 default = nil)
  if valid_603270 != nil:
    section.add "X-Amz-Date", valid_603270
  var valid_603271 = header.getOrDefault("X-Amz-Security-Token")
  valid_603271 = validateParameter(valid_603271, JString, required = false,
                                 default = nil)
  if valid_603271 != nil:
    section.add "X-Amz-Security-Token", valid_603271
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603272 = header.getOrDefault("X-Amz-Target")
  valid_603272 = validateParameter(valid_603272, JString, required = true, default = newJString(
      "KinesisAnalytics_20150814.ListTagsForResource"))
  if valid_603272 != nil:
    section.add "X-Amz-Target", valid_603272
  var valid_603273 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603273 = validateParameter(valid_603273, JString, required = false,
                                 default = nil)
  if valid_603273 != nil:
    section.add "X-Amz-Content-Sha256", valid_603273
  var valid_603274 = header.getOrDefault("X-Amz-Algorithm")
  valid_603274 = validateParameter(valid_603274, JString, required = false,
                                 default = nil)
  if valid_603274 != nil:
    section.add "X-Amz-Algorithm", valid_603274
  var valid_603275 = header.getOrDefault("X-Amz-Signature")
  valid_603275 = validateParameter(valid_603275, JString, required = false,
                                 default = nil)
  if valid_603275 != nil:
    section.add "X-Amz-Signature", valid_603275
  var valid_603276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603276 = validateParameter(valid_603276, JString, required = false,
                                 default = nil)
  if valid_603276 != nil:
    section.add "X-Amz-SignedHeaders", valid_603276
  var valid_603277 = header.getOrDefault("X-Amz-Credential")
  valid_603277 = validateParameter(valid_603277, JString, required = false,
                                 default = nil)
  if valid_603277 != nil:
    section.add "X-Amz-Credential", valid_603277
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603279: Call_ListTagsForResource_603267; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the list of key-value tags assigned to the application. For more information, see <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/how-tagging.html">Using Tagging</a>.
  ## 
  let valid = call_603279.validator(path, query, header, formData, body)
  let scheme = call_603279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603279.url(scheme.get, call_603279.host, call_603279.base,
                         call_603279.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603279, url, valid)

proc call*(call_603280: Call_ListTagsForResource_603267; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Retrieves the list of key-value tags assigned to the application. For more information, see <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/how-tagging.html">Using Tagging</a>.
  ##   body: JObject (required)
  var body_603281 = newJObject()
  if body != nil:
    body_603281 = body
  result = call_603280.call(nil, nil, nil, nil, body_603281)

var listTagsForResource* = Call_ListTagsForResource_603267(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "kinesisanalytics.amazonaws.com",
    route: "/#X-Amz-Target=KinesisAnalytics_20150814.ListTagsForResource",
    validator: validate_ListTagsForResource_603268, base: "/",
    url: url_ListTagsForResource_603269, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartApplication_603282 = ref object of OpenApiRestCall_602466
proc url_StartApplication_603284(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartApplication_603283(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <note> <p>This documentation is for version 1 of the Amazon Kinesis Data Analytics API, which only supports SQL applications. Version 2 of the API supports SQL and Java applications. For more information about version 2, see <a href="/kinesisanalytics/latest/apiv2/Welcome.html">Amazon Kinesis Data Analytics API V2 Documentation</a>.</p> </note> <p>Starts the specified Amazon Kinesis Analytics application. After creating an application, you must exclusively call this operation to start your application.</p> <p>After the application starts, it begins consuming the input data, processes it, and writes the output to the configured destination.</p> <p> The application status must be <code>READY</code> for you to start an application. You can get the application status in the console or using the <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/API_DescribeApplication.html">DescribeApplication</a> operation.</p> <p>After you start the application, you can stop the application from processing the input by calling the <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/API_StopApplication.html">StopApplication</a> operation.</p> <p>This operation requires permissions to perform the <code>kinesisanalytics:StartApplication</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603285 = header.getOrDefault("X-Amz-Date")
  valid_603285 = validateParameter(valid_603285, JString, required = false,
                                 default = nil)
  if valid_603285 != nil:
    section.add "X-Amz-Date", valid_603285
  var valid_603286 = header.getOrDefault("X-Amz-Security-Token")
  valid_603286 = validateParameter(valid_603286, JString, required = false,
                                 default = nil)
  if valid_603286 != nil:
    section.add "X-Amz-Security-Token", valid_603286
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603287 = header.getOrDefault("X-Amz-Target")
  valid_603287 = validateParameter(valid_603287, JString, required = true, default = newJString(
      "KinesisAnalytics_20150814.StartApplication"))
  if valid_603287 != nil:
    section.add "X-Amz-Target", valid_603287
  var valid_603288 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603288 = validateParameter(valid_603288, JString, required = false,
                                 default = nil)
  if valid_603288 != nil:
    section.add "X-Amz-Content-Sha256", valid_603288
  var valid_603289 = header.getOrDefault("X-Amz-Algorithm")
  valid_603289 = validateParameter(valid_603289, JString, required = false,
                                 default = nil)
  if valid_603289 != nil:
    section.add "X-Amz-Algorithm", valid_603289
  var valid_603290 = header.getOrDefault("X-Amz-Signature")
  valid_603290 = validateParameter(valid_603290, JString, required = false,
                                 default = nil)
  if valid_603290 != nil:
    section.add "X-Amz-Signature", valid_603290
  var valid_603291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603291 = validateParameter(valid_603291, JString, required = false,
                                 default = nil)
  if valid_603291 != nil:
    section.add "X-Amz-SignedHeaders", valid_603291
  var valid_603292 = header.getOrDefault("X-Amz-Credential")
  valid_603292 = validateParameter(valid_603292, JString, required = false,
                                 default = nil)
  if valid_603292 != nil:
    section.add "X-Amz-Credential", valid_603292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603294: Call_StartApplication_603282; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <note> <p>This documentation is for version 1 of the Amazon Kinesis Data Analytics API, which only supports SQL applications. Version 2 of the API supports SQL and Java applications. For more information about version 2, see <a href="/kinesisanalytics/latest/apiv2/Welcome.html">Amazon Kinesis Data Analytics API V2 Documentation</a>.</p> </note> <p>Starts the specified Amazon Kinesis Analytics application. After creating an application, you must exclusively call this operation to start your application.</p> <p>After the application starts, it begins consuming the input data, processes it, and writes the output to the configured destination.</p> <p> The application status must be <code>READY</code> for you to start an application. You can get the application status in the console or using the <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/API_DescribeApplication.html">DescribeApplication</a> operation.</p> <p>After you start the application, you can stop the application from processing the input by calling the <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/API_StopApplication.html">StopApplication</a> operation.</p> <p>This operation requires permissions to perform the <code>kinesisanalytics:StartApplication</code> action.</p>
  ## 
  let valid = call_603294.validator(path, query, header, formData, body)
  let scheme = call_603294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603294.url(scheme.get, call_603294.host, call_603294.base,
                         call_603294.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603294, url, valid)

proc call*(call_603295: Call_StartApplication_603282; body: JsonNode): Recallable =
  ## startApplication
  ## <note> <p>This documentation is for version 1 of the Amazon Kinesis Data Analytics API, which only supports SQL applications. Version 2 of the API supports SQL and Java applications. For more information about version 2, see <a href="/kinesisanalytics/latest/apiv2/Welcome.html">Amazon Kinesis Data Analytics API V2 Documentation</a>.</p> </note> <p>Starts the specified Amazon Kinesis Analytics application. After creating an application, you must exclusively call this operation to start your application.</p> <p>After the application starts, it begins consuming the input data, processes it, and writes the output to the configured destination.</p> <p> The application status must be <code>READY</code> for you to start an application. You can get the application status in the console or using the <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/API_DescribeApplication.html">DescribeApplication</a> operation.</p> <p>After you start the application, you can stop the application from processing the input by calling the <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/API_StopApplication.html">StopApplication</a> operation.</p> <p>This operation requires permissions to perform the <code>kinesisanalytics:StartApplication</code> action.</p>
  ##   body: JObject (required)
  var body_603296 = newJObject()
  if body != nil:
    body_603296 = body
  result = call_603295.call(nil, nil, nil, nil, body_603296)

var startApplication* = Call_StartApplication_603282(name: "startApplication",
    meth: HttpMethod.HttpPost, host: "kinesisanalytics.amazonaws.com",
    route: "/#X-Amz-Target=KinesisAnalytics_20150814.StartApplication",
    validator: validate_StartApplication_603283, base: "/",
    url: url_StartApplication_603284, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopApplication_603297 = ref object of OpenApiRestCall_602466
proc url_StopApplication_603299(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopApplication_603298(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <note> <p>This documentation is for version 1 of the Amazon Kinesis Data Analytics API, which only supports SQL applications. Version 2 of the API supports SQL and Java applications. For more information about version 2, see <a href="/kinesisanalytics/latest/apiv2/Welcome.html">Amazon Kinesis Data Analytics API V2 Documentation</a>.</p> </note> <p>Stops the application from processing input data. You can stop an application only if it is in the running state. You can use the <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/API_DescribeApplication.html">DescribeApplication</a> operation to find the application state. After the application is stopped, Amazon Kinesis Analytics stops reading data from the input, the application stops processing data, and there is no output written to the destination. </p> <p>This operation requires permissions to perform the <code>kinesisanalytics:StopApplication</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603300 = header.getOrDefault("X-Amz-Date")
  valid_603300 = validateParameter(valid_603300, JString, required = false,
                                 default = nil)
  if valid_603300 != nil:
    section.add "X-Amz-Date", valid_603300
  var valid_603301 = header.getOrDefault("X-Amz-Security-Token")
  valid_603301 = validateParameter(valid_603301, JString, required = false,
                                 default = nil)
  if valid_603301 != nil:
    section.add "X-Amz-Security-Token", valid_603301
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603302 = header.getOrDefault("X-Amz-Target")
  valid_603302 = validateParameter(valid_603302, JString, required = true, default = newJString(
      "KinesisAnalytics_20150814.StopApplication"))
  if valid_603302 != nil:
    section.add "X-Amz-Target", valid_603302
  var valid_603303 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603303 = validateParameter(valid_603303, JString, required = false,
                                 default = nil)
  if valid_603303 != nil:
    section.add "X-Amz-Content-Sha256", valid_603303
  var valid_603304 = header.getOrDefault("X-Amz-Algorithm")
  valid_603304 = validateParameter(valid_603304, JString, required = false,
                                 default = nil)
  if valid_603304 != nil:
    section.add "X-Amz-Algorithm", valid_603304
  var valid_603305 = header.getOrDefault("X-Amz-Signature")
  valid_603305 = validateParameter(valid_603305, JString, required = false,
                                 default = nil)
  if valid_603305 != nil:
    section.add "X-Amz-Signature", valid_603305
  var valid_603306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603306 = validateParameter(valid_603306, JString, required = false,
                                 default = nil)
  if valid_603306 != nil:
    section.add "X-Amz-SignedHeaders", valid_603306
  var valid_603307 = header.getOrDefault("X-Amz-Credential")
  valid_603307 = validateParameter(valid_603307, JString, required = false,
                                 default = nil)
  if valid_603307 != nil:
    section.add "X-Amz-Credential", valid_603307
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603309: Call_StopApplication_603297; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <note> <p>This documentation is for version 1 of the Amazon Kinesis Data Analytics API, which only supports SQL applications. Version 2 of the API supports SQL and Java applications. For more information about version 2, see <a href="/kinesisanalytics/latest/apiv2/Welcome.html">Amazon Kinesis Data Analytics API V2 Documentation</a>.</p> </note> <p>Stops the application from processing input data. You can stop an application only if it is in the running state. You can use the <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/API_DescribeApplication.html">DescribeApplication</a> operation to find the application state. After the application is stopped, Amazon Kinesis Analytics stops reading data from the input, the application stops processing data, and there is no output written to the destination. </p> <p>This operation requires permissions to perform the <code>kinesisanalytics:StopApplication</code> action.</p>
  ## 
  let valid = call_603309.validator(path, query, header, formData, body)
  let scheme = call_603309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603309.url(scheme.get, call_603309.host, call_603309.base,
                         call_603309.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603309, url, valid)

proc call*(call_603310: Call_StopApplication_603297; body: JsonNode): Recallable =
  ## stopApplication
  ## <note> <p>This documentation is for version 1 of the Amazon Kinesis Data Analytics API, which only supports SQL applications. Version 2 of the API supports SQL and Java applications. For more information about version 2, see <a href="/kinesisanalytics/latest/apiv2/Welcome.html">Amazon Kinesis Data Analytics API V2 Documentation</a>.</p> </note> <p>Stops the application from processing input data. You can stop an application only if it is in the running state. You can use the <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/API_DescribeApplication.html">DescribeApplication</a> operation to find the application state. After the application is stopped, Amazon Kinesis Analytics stops reading data from the input, the application stops processing data, and there is no output written to the destination. </p> <p>This operation requires permissions to perform the <code>kinesisanalytics:StopApplication</code> action.</p>
  ##   body: JObject (required)
  var body_603311 = newJObject()
  if body != nil:
    body_603311 = body
  result = call_603310.call(nil, nil, nil, nil, body_603311)

var stopApplication* = Call_StopApplication_603297(name: "stopApplication",
    meth: HttpMethod.HttpPost, host: "kinesisanalytics.amazonaws.com",
    route: "/#X-Amz-Target=KinesisAnalytics_20150814.StopApplication",
    validator: validate_StopApplication_603298, base: "/", url: url_StopApplication_603299,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_603312 = ref object of OpenApiRestCall_602466
proc url_TagResource_603314(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagResource_603313(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds one or more key-value tags to a Kinesis Analytics application. Note that the maximum number of application tags includes system tags. The maximum number of user-defined application tags is 50. For more information, see <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/how-tagging.html">Using Tagging</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603315 = header.getOrDefault("X-Amz-Date")
  valid_603315 = validateParameter(valid_603315, JString, required = false,
                                 default = nil)
  if valid_603315 != nil:
    section.add "X-Amz-Date", valid_603315
  var valid_603316 = header.getOrDefault("X-Amz-Security-Token")
  valid_603316 = validateParameter(valid_603316, JString, required = false,
                                 default = nil)
  if valid_603316 != nil:
    section.add "X-Amz-Security-Token", valid_603316
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603317 = header.getOrDefault("X-Amz-Target")
  valid_603317 = validateParameter(valid_603317, JString, required = true, default = newJString(
      "KinesisAnalytics_20150814.TagResource"))
  if valid_603317 != nil:
    section.add "X-Amz-Target", valid_603317
  var valid_603318 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603318 = validateParameter(valid_603318, JString, required = false,
                                 default = nil)
  if valid_603318 != nil:
    section.add "X-Amz-Content-Sha256", valid_603318
  var valid_603319 = header.getOrDefault("X-Amz-Algorithm")
  valid_603319 = validateParameter(valid_603319, JString, required = false,
                                 default = nil)
  if valid_603319 != nil:
    section.add "X-Amz-Algorithm", valid_603319
  var valid_603320 = header.getOrDefault("X-Amz-Signature")
  valid_603320 = validateParameter(valid_603320, JString, required = false,
                                 default = nil)
  if valid_603320 != nil:
    section.add "X-Amz-Signature", valid_603320
  var valid_603321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603321 = validateParameter(valid_603321, JString, required = false,
                                 default = nil)
  if valid_603321 != nil:
    section.add "X-Amz-SignedHeaders", valid_603321
  var valid_603322 = header.getOrDefault("X-Amz-Credential")
  valid_603322 = validateParameter(valid_603322, JString, required = false,
                                 default = nil)
  if valid_603322 != nil:
    section.add "X-Amz-Credential", valid_603322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603324: Call_TagResource_603312; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds one or more key-value tags to a Kinesis Analytics application. Note that the maximum number of application tags includes system tags. The maximum number of user-defined application tags is 50. For more information, see <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/how-tagging.html">Using Tagging</a>.
  ## 
  let valid = call_603324.validator(path, query, header, formData, body)
  let scheme = call_603324.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603324.url(scheme.get, call_603324.host, call_603324.base,
                         call_603324.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603324, url, valid)

proc call*(call_603325: Call_TagResource_603312; body: JsonNode): Recallable =
  ## tagResource
  ## Adds one or more key-value tags to a Kinesis Analytics application. Note that the maximum number of application tags includes system tags. The maximum number of user-defined application tags is 50. For more information, see <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/how-tagging.html">Using Tagging</a>.
  ##   body: JObject (required)
  var body_603326 = newJObject()
  if body != nil:
    body_603326 = body
  result = call_603325.call(nil, nil, nil, nil, body_603326)

var tagResource* = Call_TagResource_603312(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "kinesisanalytics.amazonaws.com", route: "/#X-Amz-Target=KinesisAnalytics_20150814.TagResource",
                                        validator: validate_TagResource_603313,
                                        base: "/", url: url_TagResource_603314,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_603327 = ref object of OpenApiRestCall_602466
proc url_UntagResource_603329(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UntagResource_603328(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes one or more tags from a Kinesis Analytics application. For more information, see <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/how-tagging.html">Using Tagging</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603330 = header.getOrDefault("X-Amz-Date")
  valid_603330 = validateParameter(valid_603330, JString, required = false,
                                 default = nil)
  if valid_603330 != nil:
    section.add "X-Amz-Date", valid_603330
  var valid_603331 = header.getOrDefault("X-Amz-Security-Token")
  valid_603331 = validateParameter(valid_603331, JString, required = false,
                                 default = nil)
  if valid_603331 != nil:
    section.add "X-Amz-Security-Token", valid_603331
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603332 = header.getOrDefault("X-Amz-Target")
  valid_603332 = validateParameter(valid_603332, JString, required = true, default = newJString(
      "KinesisAnalytics_20150814.UntagResource"))
  if valid_603332 != nil:
    section.add "X-Amz-Target", valid_603332
  var valid_603333 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603333 = validateParameter(valid_603333, JString, required = false,
                                 default = nil)
  if valid_603333 != nil:
    section.add "X-Amz-Content-Sha256", valid_603333
  var valid_603334 = header.getOrDefault("X-Amz-Algorithm")
  valid_603334 = validateParameter(valid_603334, JString, required = false,
                                 default = nil)
  if valid_603334 != nil:
    section.add "X-Amz-Algorithm", valid_603334
  var valid_603335 = header.getOrDefault("X-Amz-Signature")
  valid_603335 = validateParameter(valid_603335, JString, required = false,
                                 default = nil)
  if valid_603335 != nil:
    section.add "X-Amz-Signature", valid_603335
  var valid_603336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603336 = validateParameter(valid_603336, JString, required = false,
                                 default = nil)
  if valid_603336 != nil:
    section.add "X-Amz-SignedHeaders", valid_603336
  var valid_603337 = header.getOrDefault("X-Amz-Credential")
  valid_603337 = validateParameter(valid_603337, JString, required = false,
                                 default = nil)
  if valid_603337 != nil:
    section.add "X-Amz-Credential", valid_603337
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603339: Call_UntagResource_603327; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from a Kinesis Analytics application. For more information, see <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/how-tagging.html">Using Tagging</a>.
  ## 
  let valid = call_603339.validator(path, query, header, formData, body)
  let scheme = call_603339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603339.url(scheme.get, call_603339.host, call_603339.base,
                         call_603339.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603339, url, valid)

proc call*(call_603340: Call_UntagResource_603327; body: JsonNode): Recallable =
  ## untagResource
  ## Removes one or more tags from a Kinesis Analytics application. For more information, see <a href="https://docs.aws.amazon.com/kinesisanalytics/latest/dev/how-tagging.html">Using Tagging</a>.
  ##   body: JObject (required)
  var body_603341 = newJObject()
  if body != nil:
    body_603341 = body
  result = call_603340.call(nil, nil, nil, nil, body_603341)

var untagResource* = Call_UntagResource_603327(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "kinesisanalytics.amazonaws.com",
    route: "/#X-Amz-Target=KinesisAnalytics_20150814.UntagResource",
    validator: validate_UntagResource_603328, base: "/", url: url_UntagResource_603329,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApplication_603342 = ref object of OpenApiRestCall_602466
proc url_UpdateApplication_603344(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateApplication_603343(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <note> <p>This documentation is for version 1 of the Amazon Kinesis Data Analytics API, which only supports SQL applications. Version 2 of the API supports SQL and Java applications. For more information about version 2, see <a href="/kinesisanalytics/latest/apiv2/Welcome.html">Amazon Kinesis Data Analytics API V2 Documentation</a>.</p> </note> <p>Updates an existing Amazon Kinesis Analytics application. Using this API, you can update application code, input configuration, and output configuration. </p> <p>Note that Amazon Kinesis Analytics updates the <code>CurrentApplicationVersionId</code> each time you update your application. </p> <p>This operation requires permission for the <code>kinesisanalytics:UpdateApplication</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603345 = header.getOrDefault("X-Amz-Date")
  valid_603345 = validateParameter(valid_603345, JString, required = false,
                                 default = nil)
  if valid_603345 != nil:
    section.add "X-Amz-Date", valid_603345
  var valid_603346 = header.getOrDefault("X-Amz-Security-Token")
  valid_603346 = validateParameter(valid_603346, JString, required = false,
                                 default = nil)
  if valid_603346 != nil:
    section.add "X-Amz-Security-Token", valid_603346
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603347 = header.getOrDefault("X-Amz-Target")
  valid_603347 = validateParameter(valid_603347, JString, required = true, default = newJString(
      "KinesisAnalytics_20150814.UpdateApplication"))
  if valid_603347 != nil:
    section.add "X-Amz-Target", valid_603347
  var valid_603348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603348 = validateParameter(valid_603348, JString, required = false,
                                 default = nil)
  if valid_603348 != nil:
    section.add "X-Amz-Content-Sha256", valid_603348
  var valid_603349 = header.getOrDefault("X-Amz-Algorithm")
  valid_603349 = validateParameter(valid_603349, JString, required = false,
                                 default = nil)
  if valid_603349 != nil:
    section.add "X-Amz-Algorithm", valid_603349
  var valid_603350 = header.getOrDefault("X-Amz-Signature")
  valid_603350 = validateParameter(valid_603350, JString, required = false,
                                 default = nil)
  if valid_603350 != nil:
    section.add "X-Amz-Signature", valid_603350
  var valid_603351 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603351 = validateParameter(valid_603351, JString, required = false,
                                 default = nil)
  if valid_603351 != nil:
    section.add "X-Amz-SignedHeaders", valid_603351
  var valid_603352 = header.getOrDefault("X-Amz-Credential")
  valid_603352 = validateParameter(valid_603352, JString, required = false,
                                 default = nil)
  if valid_603352 != nil:
    section.add "X-Amz-Credential", valid_603352
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603354: Call_UpdateApplication_603342; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <note> <p>This documentation is for version 1 of the Amazon Kinesis Data Analytics API, which only supports SQL applications. Version 2 of the API supports SQL and Java applications. For more information about version 2, see <a href="/kinesisanalytics/latest/apiv2/Welcome.html">Amazon Kinesis Data Analytics API V2 Documentation</a>.</p> </note> <p>Updates an existing Amazon Kinesis Analytics application. Using this API, you can update application code, input configuration, and output configuration. </p> <p>Note that Amazon Kinesis Analytics updates the <code>CurrentApplicationVersionId</code> each time you update your application. </p> <p>This operation requires permission for the <code>kinesisanalytics:UpdateApplication</code> action.</p>
  ## 
  let valid = call_603354.validator(path, query, header, formData, body)
  let scheme = call_603354.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603354.url(scheme.get, call_603354.host, call_603354.base,
                         call_603354.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603354, url, valid)

proc call*(call_603355: Call_UpdateApplication_603342; body: JsonNode): Recallable =
  ## updateApplication
  ## <note> <p>This documentation is for version 1 of the Amazon Kinesis Data Analytics API, which only supports SQL applications. Version 2 of the API supports SQL and Java applications. For more information about version 2, see <a href="/kinesisanalytics/latest/apiv2/Welcome.html">Amazon Kinesis Data Analytics API V2 Documentation</a>.</p> </note> <p>Updates an existing Amazon Kinesis Analytics application. Using this API, you can update application code, input configuration, and output configuration. </p> <p>Note that Amazon Kinesis Analytics updates the <code>CurrentApplicationVersionId</code> each time you update your application. </p> <p>This operation requires permission for the <code>kinesisanalytics:UpdateApplication</code> action.</p>
  ##   body: JObject (required)
  var body_603356 = newJObject()
  if body != nil:
    body_603356 = body
  result = call_603355.call(nil, nil, nil, nil, body_603356)

var updateApplication* = Call_UpdateApplication_603342(name: "updateApplication",
    meth: HttpMethod.HttpPost, host: "kinesisanalytics.amazonaws.com",
    route: "/#X-Amz-Target=KinesisAnalytics_20150814.UpdateApplication",
    validator: validate_UpdateApplication_603343, base: "/",
    url: url_UpdateApplication_603344, schemes: {Scheme.Https, Scheme.Http})
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

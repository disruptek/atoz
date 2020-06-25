
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon QuickSight
## version: 2018-04-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon QuickSight API Reference</fullname> <p>Amazon QuickSight is a fully managed, serverless business intelligence service for the AWS Cloud that makes it easy to extend data and insights to every user in your organization. This API reference contains documentation for a programming interface that you can use to manage Amazon QuickSight. </p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/quicksight/
type
  Scheme {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (path: JsonNode = nil; query: JsonNode = nil;
                          header: JsonNode = nil; formData: JsonNode = nil;
                          body: JsonNode = nil; _: string = ""): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    makeUrl*: proc (protocol: Scheme; host: string; base: string; route: string;
                  path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_21625435 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625435](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625435): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low .. Scheme.high:
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
  if js == nil:
    if required:
      if default != nil:
        return validateParameter(default, kind, required = required)
  result = js
  if result == nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind == kind, $kind & " expected; received " & $js.kind

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
  awsServers = {Scheme.Http: {"ap-northeast-1": "quicksight.ap-northeast-1.amazonaws.com", "ap-southeast-1": "quicksight.ap-southeast-1.amazonaws.com",
                           "us-west-2": "quicksight.us-west-2.amazonaws.com",
                           "eu-west-2": "quicksight.eu-west-2.amazonaws.com", "ap-northeast-3": "quicksight.ap-northeast-3.amazonaws.com", "eu-central-1": "quicksight.eu-central-1.amazonaws.com",
                           "us-east-2": "quicksight.us-east-2.amazonaws.com",
                           "us-east-1": "quicksight.us-east-1.amazonaws.com", "cn-northwest-1": "quicksight.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "quicksight.ap-south-1.amazonaws.com",
                           "eu-north-1": "quicksight.eu-north-1.amazonaws.com", "ap-northeast-2": "quicksight.ap-northeast-2.amazonaws.com",
                           "us-west-1": "quicksight.us-west-1.amazonaws.com", "us-gov-east-1": "quicksight.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "quicksight.eu-west-3.amazonaws.com", "cn-north-1": "quicksight.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "quicksight.sa-east-1.amazonaws.com",
                           "eu-west-1": "quicksight.eu-west-1.amazonaws.com", "us-gov-west-1": "quicksight.us-gov-west-1.amazonaws.com", "ap-southeast-2": "quicksight.ap-southeast-2.amazonaws.com", "ca-central-1": "quicksight.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "quicksight.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "quicksight.ap-southeast-1.amazonaws.com",
      "us-west-2": "quicksight.us-west-2.amazonaws.com",
      "eu-west-2": "quicksight.eu-west-2.amazonaws.com",
      "ap-northeast-3": "quicksight.ap-northeast-3.amazonaws.com",
      "eu-central-1": "quicksight.eu-central-1.amazonaws.com",
      "us-east-2": "quicksight.us-east-2.amazonaws.com",
      "us-east-1": "quicksight.us-east-1.amazonaws.com",
      "cn-northwest-1": "quicksight.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "quicksight.ap-south-1.amazonaws.com",
      "eu-north-1": "quicksight.eu-north-1.amazonaws.com",
      "ap-northeast-2": "quicksight.ap-northeast-2.amazonaws.com",
      "us-west-1": "quicksight.us-west-1.amazonaws.com",
      "us-gov-east-1": "quicksight.us-gov-east-1.amazonaws.com",
      "eu-west-3": "quicksight.eu-west-3.amazonaws.com",
      "cn-north-1": "quicksight.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "quicksight.sa-east-1.amazonaws.com",
      "eu-west-1": "quicksight.eu-west-1.amazonaws.com",
      "us-gov-west-1": "quicksight.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "quicksight.ap-southeast-2.amazonaws.com",
      "ca-central-1": "quicksight.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "quicksight"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_CreateIngestion_21626032 = ref object of OpenApiRestCall_21625435
proc url_CreateIngestion_21626034(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  assert "IngestionId" in path, "`IngestionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/data-sets/"),
               (kind: VariableSegment, value: "DataSetId"),
               (kind: ConstantSegment, value: "/ingestions/"),
               (kind: VariableSegment, value: "IngestionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateIngestion_21626033(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates and starts a new SPICE ingestion on a dataset</p> <p>Any ingestions operating on tagged datasets inherit the same tags automatically for use in access control. For an example, see <a href="https://aws.example.com/premiumsupport/knowledge-center/iam-ec2-resource-tags/">How do I create an IAM policy to control access to Amazon EC2 resources using tags?</a> in the AWS Knowledge Center. Tags are visible on the tagged dataset, but not on the ingestion resource.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID.
  ##   DataSetId: JString (required)
  ##            : The ID of the dataset used in the ingestion.
  ##   IngestionId: JString (required)
  ##              : An ID for the ingestion.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_21626035 = path.getOrDefault("AwsAccountId")
  valid_21626035 = validateParameter(valid_21626035, JString, required = true,
                                   default = nil)
  if valid_21626035 != nil:
    section.add "AwsAccountId", valid_21626035
  var valid_21626036 = path.getOrDefault("DataSetId")
  valid_21626036 = validateParameter(valid_21626036, JString, required = true,
                                   default = nil)
  if valid_21626036 != nil:
    section.add "DataSetId", valid_21626036
  var valid_21626037 = path.getOrDefault("IngestionId")
  valid_21626037 = validateParameter(valid_21626037, JString, required = true,
                                   default = nil)
  if valid_21626037 != nil:
    section.add "IngestionId", valid_21626037
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626038 = header.getOrDefault("X-Amz-Date")
  valid_21626038 = validateParameter(valid_21626038, JString, required = false,
                                   default = nil)
  if valid_21626038 != nil:
    section.add "X-Amz-Date", valid_21626038
  var valid_21626039 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626039 = validateParameter(valid_21626039, JString, required = false,
                                   default = nil)
  if valid_21626039 != nil:
    section.add "X-Amz-Security-Token", valid_21626039
  var valid_21626040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626040 = validateParameter(valid_21626040, JString, required = false,
                                   default = nil)
  if valid_21626040 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626040
  var valid_21626041 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626041 = validateParameter(valid_21626041, JString, required = false,
                                   default = nil)
  if valid_21626041 != nil:
    section.add "X-Amz-Algorithm", valid_21626041
  var valid_21626042 = header.getOrDefault("X-Amz-Signature")
  valid_21626042 = validateParameter(valid_21626042, JString, required = false,
                                   default = nil)
  if valid_21626042 != nil:
    section.add "X-Amz-Signature", valid_21626042
  var valid_21626043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626043 = validateParameter(valid_21626043, JString, required = false,
                                   default = nil)
  if valid_21626043 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626043
  var valid_21626044 = header.getOrDefault("X-Amz-Credential")
  valid_21626044 = validateParameter(valid_21626044, JString, required = false,
                                   default = nil)
  if valid_21626044 != nil:
    section.add "X-Amz-Credential", valid_21626044
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626045: Call_CreateIngestion_21626032; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates and starts a new SPICE ingestion on a dataset</p> <p>Any ingestions operating on tagged datasets inherit the same tags automatically for use in access control. For an example, see <a href="https://aws.example.com/premiumsupport/knowledge-center/iam-ec2-resource-tags/">How do I create an IAM policy to control access to Amazon EC2 resources using tags?</a> in the AWS Knowledge Center. Tags are visible on the tagged dataset, but not on the ingestion resource.</p>
  ## 
  let valid = call_21626045.validator(path, query, header, formData, body, _)
  let scheme = call_21626045.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626045.makeUrl(scheme.get, call_21626045.host, call_21626045.base,
                               call_21626045.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626045, uri, valid, _)

proc call*(call_21626046: Call_CreateIngestion_21626032; AwsAccountId: string;
          DataSetId: string; IngestionId: string): Recallable =
  ## createIngestion
  ## <p>Creates and starts a new SPICE ingestion on a dataset</p> <p>Any ingestions operating on tagged datasets inherit the same tags automatically for use in access control. For an example, see <a href="https://aws.example.com/premiumsupport/knowledge-center/iam-ec2-resource-tags/">How do I create an IAM policy to control access to Amazon EC2 resources using tags?</a> in the AWS Knowledge Center. Tags are visible on the tagged dataset, but not on the ingestion resource.</p>
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSetId: string (required)
  ##            : The ID of the dataset used in the ingestion.
  ##   IngestionId: string (required)
  ##              : An ID for the ingestion.
  var path_21626047 = newJObject()
  add(path_21626047, "AwsAccountId", newJString(AwsAccountId))
  add(path_21626047, "DataSetId", newJString(DataSetId))
  add(path_21626047, "IngestionId", newJString(IngestionId))
  result = call_21626046.call(path_21626047, nil, nil, nil, nil)

var createIngestion* = Call_CreateIngestion_21626032(name: "createIngestion",
    meth: HttpMethod.HttpPut, host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}/ingestions/{IngestionId}",
    validator: validate_CreateIngestion_21626033, base: "/",
    makeUrl: url_CreateIngestion_21626034, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeIngestion_21625779 = ref object of OpenApiRestCall_21625435
proc url_DescribeIngestion_21625781(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  assert "IngestionId" in path, "`IngestionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/data-sets/"),
               (kind: VariableSegment, value: "DataSetId"),
               (kind: ConstantSegment, value: "/ingestions/"),
               (kind: VariableSegment, value: "IngestionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeIngestion_21625780(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Describes a SPICE ingestion.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID.
  ##   DataSetId: JString (required)
  ##            : The ID of the dataset used in the ingestion.
  ##   IngestionId: JString (required)
  ##              : An ID for the ingestion.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_21625895 = path.getOrDefault("AwsAccountId")
  valid_21625895 = validateParameter(valid_21625895, JString, required = true,
                                   default = nil)
  if valid_21625895 != nil:
    section.add "AwsAccountId", valid_21625895
  var valid_21625896 = path.getOrDefault("DataSetId")
  valid_21625896 = validateParameter(valid_21625896, JString, required = true,
                                   default = nil)
  if valid_21625896 != nil:
    section.add "DataSetId", valid_21625896
  var valid_21625897 = path.getOrDefault("IngestionId")
  valid_21625897 = validateParameter(valid_21625897, JString, required = true,
                                   default = nil)
  if valid_21625897 != nil:
    section.add "IngestionId", valid_21625897
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21625898 = header.getOrDefault("X-Amz-Date")
  valid_21625898 = validateParameter(valid_21625898, JString, required = false,
                                   default = nil)
  if valid_21625898 != nil:
    section.add "X-Amz-Date", valid_21625898
  var valid_21625899 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625899 = validateParameter(valid_21625899, JString, required = false,
                                   default = nil)
  if valid_21625899 != nil:
    section.add "X-Amz-Security-Token", valid_21625899
  var valid_21625900 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625900 = validateParameter(valid_21625900, JString, required = false,
                                   default = nil)
  if valid_21625900 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625900
  var valid_21625901 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625901 = validateParameter(valid_21625901, JString, required = false,
                                   default = nil)
  if valid_21625901 != nil:
    section.add "X-Amz-Algorithm", valid_21625901
  var valid_21625902 = header.getOrDefault("X-Amz-Signature")
  valid_21625902 = validateParameter(valid_21625902, JString, required = false,
                                   default = nil)
  if valid_21625902 != nil:
    section.add "X-Amz-Signature", valid_21625902
  var valid_21625903 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625903 = validateParameter(valid_21625903, JString, required = false,
                                   default = nil)
  if valid_21625903 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625903
  var valid_21625904 = header.getOrDefault("X-Amz-Credential")
  valid_21625904 = validateParameter(valid_21625904, JString, required = false,
                                   default = nil)
  if valid_21625904 != nil:
    section.add "X-Amz-Credential", valid_21625904
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21625929: Call_DescribeIngestion_21625779; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes a SPICE ingestion.
  ## 
  let valid = call_21625929.validator(path, query, header, formData, body, _)
  let scheme = call_21625929.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625929.makeUrl(scheme.get, call_21625929.host, call_21625929.base,
                               call_21625929.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625929, uri, valid, _)

proc call*(call_21625992: Call_DescribeIngestion_21625779; AwsAccountId: string;
          DataSetId: string; IngestionId: string): Recallable =
  ## describeIngestion
  ## Describes a SPICE ingestion.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSetId: string (required)
  ##            : The ID of the dataset used in the ingestion.
  ##   IngestionId: string (required)
  ##              : An ID for the ingestion.
  var path_21625994 = newJObject()
  add(path_21625994, "AwsAccountId", newJString(AwsAccountId))
  add(path_21625994, "DataSetId", newJString(DataSetId))
  add(path_21625994, "IngestionId", newJString(IngestionId))
  result = call_21625992.call(path_21625994, nil, nil, nil, nil)

var describeIngestion* = Call_DescribeIngestion_21625779(name: "describeIngestion",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}/ingestions/{IngestionId}",
    validator: validate_DescribeIngestion_21625780, base: "/",
    makeUrl: url_DescribeIngestion_21625781, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelIngestion_21626048 = ref object of OpenApiRestCall_21625435
proc url_CancelIngestion_21626050(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  assert "IngestionId" in path, "`IngestionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/data-sets/"),
               (kind: VariableSegment, value: "DataSetId"),
               (kind: ConstantSegment, value: "/ingestions/"),
               (kind: VariableSegment, value: "IngestionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CancelIngestion_21626049(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Cancels an ongoing ingestion of data into SPICE.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID.
  ##   DataSetId: JString (required)
  ##            : The ID of the dataset used in the ingestion.
  ##   IngestionId: JString (required)
  ##              : An ID for the ingestion.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_21626051 = path.getOrDefault("AwsAccountId")
  valid_21626051 = validateParameter(valid_21626051, JString, required = true,
                                   default = nil)
  if valid_21626051 != nil:
    section.add "AwsAccountId", valid_21626051
  var valid_21626052 = path.getOrDefault("DataSetId")
  valid_21626052 = validateParameter(valid_21626052, JString, required = true,
                                   default = nil)
  if valid_21626052 != nil:
    section.add "DataSetId", valid_21626052
  var valid_21626053 = path.getOrDefault("IngestionId")
  valid_21626053 = validateParameter(valid_21626053, JString, required = true,
                                   default = nil)
  if valid_21626053 != nil:
    section.add "IngestionId", valid_21626053
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626054 = header.getOrDefault("X-Amz-Date")
  valid_21626054 = validateParameter(valid_21626054, JString, required = false,
                                   default = nil)
  if valid_21626054 != nil:
    section.add "X-Amz-Date", valid_21626054
  var valid_21626055 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626055 = validateParameter(valid_21626055, JString, required = false,
                                   default = nil)
  if valid_21626055 != nil:
    section.add "X-Amz-Security-Token", valid_21626055
  var valid_21626056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626056 = validateParameter(valid_21626056, JString, required = false,
                                   default = nil)
  if valid_21626056 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626056
  var valid_21626057 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626057 = validateParameter(valid_21626057, JString, required = false,
                                   default = nil)
  if valid_21626057 != nil:
    section.add "X-Amz-Algorithm", valid_21626057
  var valid_21626058 = header.getOrDefault("X-Amz-Signature")
  valid_21626058 = validateParameter(valid_21626058, JString, required = false,
                                   default = nil)
  if valid_21626058 != nil:
    section.add "X-Amz-Signature", valid_21626058
  var valid_21626059 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626059 = validateParameter(valid_21626059, JString, required = false,
                                   default = nil)
  if valid_21626059 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626059
  var valid_21626060 = header.getOrDefault("X-Amz-Credential")
  valid_21626060 = validateParameter(valid_21626060, JString, required = false,
                                   default = nil)
  if valid_21626060 != nil:
    section.add "X-Amz-Credential", valid_21626060
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626061: Call_CancelIngestion_21626048; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Cancels an ongoing ingestion of data into SPICE.
  ## 
  let valid = call_21626061.validator(path, query, header, formData, body, _)
  let scheme = call_21626061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626061.makeUrl(scheme.get, call_21626061.host, call_21626061.base,
                               call_21626061.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626061, uri, valid, _)

proc call*(call_21626062: Call_CancelIngestion_21626048; AwsAccountId: string;
          DataSetId: string; IngestionId: string): Recallable =
  ## cancelIngestion
  ## Cancels an ongoing ingestion of data into SPICE.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSetId: string (required)
  ##            : The ID of the dataset used in the ingestion.
  ##   IngestionId: string (required)
  ##              : An ID for the ingestion.
  var path_21626063 = newJObject()
  add(path_21626063, "AwsAccountId", newJString(AwsAccountId))
  add(path_21626063, "DataSetId", newJString(DataSetId))
  add(path_21626063, "IngestionId", newJString(IngestionId))
  result = call_21626062.call(path_21626063, nil, nil, nil, nil)

var cancelIngestion* = Call_CancelIngestion_21626048(name: "cancelIngestion",
    meth: HttpMethod.HttpDelete, host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}/ingestions/{IngestionId}",
    validator: validate_CancelIngestion_21626049, base: "/",
    makeUrl: url_CancelIngestion_21626050, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDashboard_21626083 = ref object of OpenApiRestCall_21625435
proc url_UpdateDashboard_21626085(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "DashboardId" in path, "`DashboardId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/dashboards/"),
               (kind: VariableSegment, value: "DashboardId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDashboard_21626084(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates a dashboard in an AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account that contains the dashboard that you're updating.
  ##   DashboardId: JString (required)
  ##              : The ID for the dashboard.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_21626086 = path.getOrDefault("AwsAccountId")
  valid_21626086 = validateParameter(valid_21626086, JString, required = true,
                                   default = nil)
  if valid_21626086 != nil:
    section.add "AwsAccountId", valid_21626086
  var valid_21626087 = path.getOrDefault("DashboardId")
  valid_21626087 = validateParameter(valid_21626087, JString, required = true,
                                   default = nil)
  if valid_21626087 != nil:
    section.add "DashboardId", valid_21626087
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626088 = header.getOrDefault("X-Amz-Date")
  valid_21626088 = validateParameter(valid_21626088, JString, required = false,
                                   default = nil)
  if valid_21626088 != nil:
    section.add "X-Amz-Date", valid_21626088
  var valid_21626089 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626089 = validateParameter(valid_21626089, JString, required = false,
                                   default = nil)
  if valid_21626089 != nil:
    section.add "X-Amz-Security-Token", valid_21626089
  var valid_21626090 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626090 = validateParameter(valid_21626090, JString, required = false,
                                   default = nil)
  if valid_21626090 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626090
  var valid_21626091 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626091 = validateParameter(valid_21626091, JString, required = false,
                                   default = nil)
  if valid_21626091 != nil:
    section.add "X-Amz-Algorithm", valid_21626091
  var valid_21626092 = header.getOrDefault("X-Amz-Signature")
  valid_21626092 = validateParameter(valid_21626092, JString, required = false,
                                   default = nil)
  if valid_21626092 != nil:
    section.add "X-Amz-Signature", valid_21626092
  var valid_21626093 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626093 = validateParameter(valid_21626093, JString, required = false,
                                   default = nil)
  if valid_21626093 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626093
  var valid_21626094 = header.getOrDefault("X-Amz-Credential")
  valid_21626094 = validateParameter(valid_21626094, JString, required = false,
                                   default = nil)
  if valid_21626094 != nil:
    section.add "X-Amz-Credential", valid_21626094
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626096: Call_UpdateDashboard_21626083; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a dashboard in an AWS account.
  ## 
  let valid = call_21626096.validator(path, query, header, formData, body, _)
  let scheme = call_21626096.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626096.makeUrl(scheme.get, call_21626096.host, call_21626096.base,
                               call_21626096.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626096, uri, valid, _)

proc call*(call_21626097: Call_UpdateDashboard_21626083; AwsAccountId: string;
          DashboardId: string; body: JsonNode): Recallable =
  ## updateDashboard
  ## Updates a dashboard in an AWS account.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the dashboard that you're updating.
  ##   DashboardId: string (required)
  ##              : The ID for the dashboard.
  ##   body: JObject (required)
  var path_21626098 = newJObject()
  var body_21626099 = newJObject()
  add(path_21626098, "AwsAccountId", newJString(AwsAccountId))
  add(path_21626098, "DashboardId", newJString(DashboardId))
  if body != nil:
    body_21626099 = body
  result = call_21626097.call(path_21626098, nil, nil, nil, body_21626099)

var updateDashboard* = Call_UpdateDashboard_21626083(name: "updateDashboard",
    meth: HttpMethod.HttpPut, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}",
    validator: validate_UpdateDashboard_21626084, base: "/",
    makeUrl: url_UpdateDashboard_21626085, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDashboard_21626100 = ref object of OpenApiRestCall_21625435
proc url_CreateDashboard_21626102(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "DashboardId" in path, "`DashboardId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/dashboards/"),
               (kind: VariableSegment, value: "DashboardId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateDashboard_21626101(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a dashboard from a template. To first create a template, see the CreateTemplate API operation.</p> <p>A dashboard is an entity in QuickSight that identifies QuickSight reports, created from analyses. You can share QuickSight dashboards. With the right permissions, you can create scheduled email reports from them. The <code>CreateDashboard</code>, <code>DescribeDashboard</code>, and <code>ListDashboardsByUser</code> API operations act on the dashboard entity. If you have the correct permissions, you can create a dashboard from a template that exists in a different AWS account.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account where you want to create the dashboard.
  ##   DashboardId: JString (required)
  ##              : The ID for the dashboard, also added to the IAM policy.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_21626103 = path.getOrDefault("AwsAccountId")
  valid_21626103 = validateParameter(valid_21626103, JString, required = true,
                                   default = nil)
  if valid_21626103 != nil:
    section.add "AwsAccountId", valid_21626103
  var valid_21626104 = path.getOrDefault("DashboardId")
  valid_21626104 = validateParameter(valid_21626104, JString, required = true,
                                   default = nil)
  if valid_21626104 != nil:
    section.add "DashboardId", valid_21626104
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626105 = header.getOrDefault("X-Amz-Date")
  valid_21626105 = validateParameter(valid_21626105, JString, required = false,
                                   default = nil)
  if valid_21626105 != nil:
    section.add "X-Amz-Date", valid_21626105
  var valid_21626106 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626106 = validateParameter(valid_21626106, JString, required = false,
                                   default = nil)
  if valid_21626106 != nil:
    section.add "X-Amz-Security-Token", valid_21626106
  var valid_21626107 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626107 = validateParameter(valid_21626107, JString, required = false,
                                   default = nil)
  if valid_21626107 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626107
  var valid_21626108 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626108 = validateParameter(valid_21626108, JString, required = false,
                                   default = nil)
  if valid_21626108 != nil:
    section.add "X-Amz-Algorithm", valid_21626108
  var valid_21626109 = header.getOrDefault("X-Amz-Signature")
  valid_21626109 = validateParameter(valid_21626109, JString, required = false,
                                   default = nil)
  if valid_21626109 != nil:
    section.add "X-Amz-Signature", valid_21626109
  var valid_21626110 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626110 = validateParameter(valid_21626110, JString, required = false,
                                   default = nil)
  if valid_21626110 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626110
  var valid_21626111 = header.getOrDefault("X-Amz-Credential")
  valid_21626111 = validateParameter(valid_21626111, JString, required = false,
                                   default = nil)
  if valid_21626111 != nil:
    section.add "X-Amz-Credential", valid_21626111
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626113: Call_CreateDashboard_21626100; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a dashboard from a template. To first create a template, see the CreateTemplate API operation.</p> <p>A dashboard is an entity in QuickSight that identifies QuickSight reports, created from analyses. You can share QuickSight dashboards. With the right permissions, you can create scheduled email reports from them. The <code>CreateDashboard</code>, <code>DescribeDashboard</code>, and <code>ListDashboardsByUser</code> API operations act on the dashboard entity. If you have the correct permissions, you can create a dashboard from a template that exists in a different AWS account.</p>
  ## 
  let valid = call_21626113.validator(path, query, header, formData, body, _)
  let scheme = call_21626113.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626113.makeUrl(scheme.get, call_21626113.host, call_21626113.base,
                               call_21626113.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626113, uri, valid, _)

proc call*(call_21626114: Call_CreateDashboard_21626100; AwsAccountId: string;
          DashboardId: string; body: JsonNode): Recallable =
  ## createDashboard
  ## <p>Creates a dashboard from a template. To first create a template, see the CreateTemplate API operation.</p> <p>A dashboard is an entity in QuickSight that identifies QuickSight reports, created from analyses. You can share QuickSight dashboards. With the right permissions, you can create scheduled email reports from them. The <code>CreateDashboard</code>, <code>DescribeDashboard</code>, and <code>ListDashboardsByUser</code> API operations act on the dashboard entity. If you have the correct permissions, you can create a dashboard from a template that exists in a different AWS account.</p>
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account where you want to create the dashboard.
  ##   DashboardId: string (required)
  ##              : The ID for the dashboard, also added to the IAM policy.
  ##   body: JObject (required)
  var path_21626115 = newJObject()
  var body_21626116 = newJObject()
  add(path_21626115, "AwsAccountId", newJString(AwsAccountId))
  add(path_21626115, "DashboardId", newJString(DashboardId))
  if body != nil:
    body_21626116 = body
  result = call_21626114.call(path_21626115, nil, nil, nil, body_21626116)

var createDashboard* = Call_CreateDashboard_21626100(name: "createDashboard",
    meth: HttpMethod.HttpPost, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}",
    validator: validate_CreateDashboard_21626101, base: "/",
    makeUrl: url_CreateDashboard_21626102, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDashboard_21626064 = ref object of OpenApiRestCall_21625435
proc url_DescribeDashboard_21626066(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "DashboardId" in path, "`DashboardId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/dashboards/"),
               (kind: VariableSegment, value: "DashboardId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeDashboard_21626065(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Provides a summary for a dashboard.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account that contains the dashboard that you're describing.
  ##   DashboardId: JString (required)
  ##              : The ID for the dashboard.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_21626067 = path.getOrDefault("AwsAccountId")
  valid_21626067 = validateParameter(valid_21626067, JString, required = true,
                                   default = nil)
  if valid_21626067 != nil:
    section.add "AwsAccountId", valid_21626067
  var valid_21626068 = path.getOrDefault("DashboardId")
  valid_21626068 = validateParameter(valid_21626068, JString, required = true,
                                   default = nil)
  if valid_21626068 != nil:
    section.add "DashboardId", valid_21626068
  result.add "path", section
  ## parameters in `query` object:
  ##   alias-name: JString
  ##             : The alias name.
  ##   version-number: JInt
  ##                 : The version number for the dashboard. If a version number isn't passed, the latest published dashboard version is described. 
  section = newJObject()
  var valid_21626069 = query.getOrDefault("alias-name")
  valid_21626069 = validateParameter(valid_21626069, JString, required = false,
                                   default = nil)
  if valid_21626069 != nil:
    section.add "alias-name", valid_21626069
  var valid_21626070 = query.getOrDefault("version-number")
  valid_21626070 = validateParameter(valid_21626070, JInt, required = false,
                                   default = nil)
  if valid_21626070 != nil:
    section.add "version-number", valid_21626070
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626071 = header.getOrDefault("X-Amz-Date")
  valid_21626071 = validateParameter(valid_21626071, JString, required = false,
                                   default = nil)
  if valid_21626071 != nil:
    section.add "X-Amz-Date", valid_21626071
  var valid_21626072 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626072 = validateParameter(valid_21626072, JString, required = false,
                                   default = nil)
  if valid_21626072 != nil:
    section.add "X-Amz-Security-Token", valid_21626072
  var valid_21626073 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626073 = validateParameter(valid_21626073, JString, required = false,
                                   default = nil)
  if valid_21626073 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626073
  var valid_21626074 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626074 = validateParameter(valid_21626074, JString, required = false,
                                   default = nil)
  if valid_21626074 != nil:
    section.add "X-Amz-Algorithm", valid_21626074
  var valid_21626075 = header.getOrDefault("X-Amz-Signature")
  valid_21626075 = validateParameter(valid_21626075, JString, required = false,
                                   default = nil)
  if valid_21626075 != nil:
    section.add "X-Amz-Signature", valid_21626075
  var valid_21626076 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626076 = validateParameter(valid_21626076, JString, required = false,
                                   default = nil)
  if valid_21626076 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626076
  var valid_21626077 = header.getOrDefault("X-Amz-Credential")
  valid_21626077 = validateParameter(valid_21626077, JString, required = false,
                                   default = nil)
  if valid_21626077 != nil:
    section.add "X-Amz-Credential", valid_21626077
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626078: Call_DescribeDashboard_21626064; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Provides a summary for a dashboard.
  ## 
  let valid = call_21626078.validator(path, query, header, formData, body, _)
  let scheme = call_21626078.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626078.makeUrl(scheme.get, call_21626078.host, call_21626078.base,
                               call_21626078.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626078, uri, valid, _)

proc call*(call_21626079: Call_DescribeDashboard_21626064; AwsAccountId: string;
          DashboardId: string; aliasName: string = ""; versionNumber: int = 0): Recallable =
  ## describeDashboard
  ## Provides a summary for a dashboard.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the dashboard that you're describing.
  ##   DashboardId: string (required)
  ##              : The ID for the dashboard.
  ##   aliasName: string
  ##            : The alias name.
  ##   versionNumber: int
  ##                : The version number for the dashboard. If a version number isn't passed, the latest published dashboard version is described. 
  var path_21626080 = newJObject()
  var query_21626081 = newJObject()
  add(path_21626080, "AwsAccountId", newJString(AwsAccountId))
  add(path_21626080, "DashboardId", newJString(DashboardId))
  add(query_21626081, "alias-name", newJString(aliasName))
  add(query_21626081, "version-number", newJInt(versionNumber))
  result = call_21626079.call(path_21626080, query_21626081, nil, nil, nil)

var describeDashboard* = Call_DescribeDashboard_21626064(name: "describeDashboard",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}",
    validator: validate_DescribeDashboard_21626065, base: "/",
    makeUrl: url_DescribeDashboard_21626066, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDashboard_21626117 = ref object of OpenApiRestCall_21625435
proc url_DeleteDashboard_21626119(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "DashboardId" in path, "`DashboardId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/dashboards/"),
               (kind: VariableSegment, value: "DashboardId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDashboard_21626118(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a dashboard.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account that contains the dashboard that you're deleting.
  ##   DashboardId: JString (required)
  ##              : The ID for the dashboard.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_21626120 = path.getOrDefault("AwsAccountId")
  valid_21626120 = validateParameter(valid_21626120, JString, required = true,
                                   default = nil)
  if valid_21626120 != nil:
    section.add "AwsAccountId", valid_21626120
  var valid_21626121 = path.getOrDefault("DashboardId")
  valid_21626121 = validateParameter(valid_21626121, JString, required = true,
                                   default = nil)
  if valid_21626121 != nil:
    section.add "DashboardId", valid_21626121
  result.add "path", section
  ## parameters in `query` object:
  ##   version-number: JInt
  ##                 : The version number of the dashboard. If the version number property is provided, only the specified version of the dashboard is deleted.
  section = newJObject()
  var valid_21626122 = query.getOrDefault("version-number")
  valid_21626122 = validateParameter(valid_21626122, JInt, required = false,
                                   default = nil)
  if valid_21626122 != nil:
    section.add "version-number", valid_21626122
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626123 = header.getOrDefault("X-Amz-Date")
  valid_21626123 = validateParameter(valid_21626123, JString, required = false,
                                   default = nil)
  if valid_21626123 != nil:
    section.add "X-Amz-Date", valid_21626123
  var valid_21626124 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626124 = validateParameter(valid_21626124, JString, required = false,
                                   default = nil)
  if valid_21626124 != nil:
    section.add "X-Amz-Security-Token", valid_21626124
  var valid_21626125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626125 = validateParameter(valid_21626125, JString, required = false,
                                   default = nil)
  if valid_21626125 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626125
  var valid_21626126 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626126 = validateParameter(valid_21626126, JString, required = false,
                                   default = nil)
  if valid_21626126 != nil:
    section.add "X-Amz-Algorithm", valid_21626126
  var valid_21626127 = header.getOrDefault("X-Amz-Signature")
  valid_21626127 = validateParameter(valid_21626127, JString, required = false,
                                   default = nil)
  if valid_21626127 != nil:
    section.add "X-Amz-Signature", valid_21626127
  var valid_21626128 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626128 = validateParameter(valid_21626128, JString, required = false,
                                   default = nil)
  if valid_21626128 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626128
  var valid_21626129 = header.getOrDefault("X-Amz-Credential")
  valid_21626129 = validateParameter(valid_21626129, JString, required = false,
                                   default = nil)
  if valid_21626129 != nil:
    section.add "X-Amz-Credential", valid_21626129
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626130: Call_DeleteDashboard_21626117; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a dashboard.
  ## 
  let valid = call_21626130.validator(path, query, header, formData, body, _)
  let scheme = call_21626130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626130.makeUrl(scheme.get, call_21626130.host, call_21626130.base,
                               call_21626130.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626130, uri, valid, _)

proc call*(call_21626131: Call_DeleteDashboard_21626117; AwsAccountId: string;
          DashboardId: string; versionNumber: int = 0): Recallable =
  ## deleteDashboard
  ## Deletes a dashboard.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the dashboard that you're deleting.
  ##   DashboardId: string (required)
  ##              : The ID for the dashboard.
  ##   versionNumber: int
  ##                : The version number of the dashboard. If the version number property is provided, only the specified version of the dashboard is deleted.
  var path_21626132 = newJObject()
  var query_21626133 = newJObject()
  add(path_21626132, "AwsAccountId", newJString(AwsAccountId))
  add(path_21626132, "DashboardId", newJString(DashboardId))
  add(query_21626133, "version-number", newJInt(versionNumber))
  result = call_21626131.call(path_21626132, query_21626133, nil, nil, nil)

var deleteDashboard* = Call_DeleteDashboard_21626117(name: "deleteDashboard",
    meth: HttpMethod.HttpDelete, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}",
    validator: validate_DeleteDashboard_21626118, base: "/",
    makeUrl: url_DeleteDashboard_21626119, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataSet_21626153 = ref object of OpenApiRestCall_21625435
proc url_CreateDataSet_21626155(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/data-sets")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateDataSet_21626154(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Creates a dataset.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_21626156 = path.getOrDefault("AwsAccountId")
  valid_21626156 = validateParameter(valid_21626156, JString, required = true,
                                   default = nil)
  if valid_21626156 != nil:
    section.add "AwsAccountId", valid_21626156
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626157 = header.getOrDefault("X-Amz-Date")
  valid_21626157 = validateParameter(valid_21626157, JString, required = false,
                                   default = nil)
  if valid_21626157 != nil:
    section.add "X-Amz-Date", valid_21626157
  var valid_21626158 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626158 = validateParameter(valid_21626158, JString, required = false,
                                   default = nil)
  if valid_21626158 != nil:
    section.add "X-Amz-Security-Token", valid_21626158
  var valid_21626159 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626159 = validateParameter(valid_21626159, JString, required = false,
                                   default = nil)
  if valid_21626159 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626159
  var valid_21626160 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626160 = validateParameter(valid_21626160, JString, required = false,
                                   default = nil)
  if valid_21626160 != nil:
    section.add "X-Amz-Algorithm", valid_21626160
  var valid_21626161 = header.getOrDefault("X-Amz-Signature")
  valid_21626161 = validateParameter(valid_21626161, JString, required = false,
                                   default = nil)
  if valid_21626161 != nil:
    section.add "X-Amz-Signature", valid_21626161
  var valid_21626162 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626162 = validateParameter(valid_21626162, JString, required = false,
                                   default = nil)
  if valid_21626162 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626162
  var valid_21626163 = header.getOrDefault("X-Amz-Credential")
  valid_21626163 = validateParameter(valid_21626163, JString, required = false,
                                   default = nil)
  if valid_21626163 != nil:
    section.add "X-Amz-Credential", valid_21626163
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626165: Call_CreateDataSet_21626153; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a dataset.
  ## 
  let valid = call_21626165.validator(path, query, header, formData, body, _)
  let scheme = call_21626165.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626165.makeUrl(scheme.get, call_21626165.host, call_21626165.base,
                               call_21626165.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626165, uri, valid, _)

proc call*(call_21626166: Call_CreateDataSet_21626153; AwsAccountId: string;
          body: JsonNode): Recallable =
  ## createDataSet
  ## Creates a dataset.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   body: JObject (required)
  var path_21626167 = newJObject()
  var body_21626168 = newJObject()
  add(path_21626167, "AwsAccountId", newJString(AwsAccountId))
  if body != nil:
    body_21626168 = body
  result = call_21626166.call(path_21626167, nil, nil, nil, body_21626168)

var createDataSet* = Call_CreateDataSet_21626153(name: "createDataSet",
    meth: HttpMethod.HttpPost, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sets",
    validator: validate_CreateDataSet_21626154, base: "/",
    makeUrl: url_CreateDataSet_21626155, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDataSets_21626134 = ref object of OpenApiRestCall_21625435
proc url_ListDataSets_21626136(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/data-sets")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListDataSets_21626135(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p>Lists all of the datasets belonging to the current AWS account in an AWS Region.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:dataset/*</code>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_21626137 = path.getOrDefault("AwsAccountId")
  valid_21626137 = validateParameter(valid_21626137, JString, required = true,
                                   default = nil)
  if valid_21626137 != nil:
    section.add "AwsAccountId", valid_21626137
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   max-results: JInt
  ##              : The maximum number of results to be returned per request.
  ##   next-token: JString
  ##             : The token for the next set of results, or null if there are no more results.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626138 = query.getOrDefault("NextToken")
  valid_21626138 = validateParameter(valid_21626138, JString, required = false,
                                   default = nil)
  if valid_21626138 != nil:
    section.add "NextToken", valid_21626138
  var valid_21626139 = query.getOrDefault("max-results")
  valid_21626139 = validateParameter(valid_21626139, JInt, required = false,
                                   default = nil)
  if valid_21626139 != nil:
    section.add "max-results", valid_21626139
  var valid_21626140 = query.getOrDefault("next-token")
  valid_21626140 = validateParameter(valid_21626140, JString, required = false,
                                   default = nil)
  if valid_21626140 != nil:
    section.add "next-token", valid_21626140
  var valid_21626141 = query.getOrDefault("MaxResults")
  valid_21626141 = validateParameter(valid_21626141, JString, required = false,
                                   default = nil)
  if valid_21626141 != nil:
    section.add "MaxResults", valid_21626141
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626142 = header.getOrDefault("X-Amz-Date")
  valid_21626142 = validateParameter(valid_21626142, JString, required = false,
                                   default = nil)
  if valid_21626142 != nil:
    section.add "X-Amz-Date", valid_21626142
  var valid_21626143 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626143 = validateParameter(valid_21626143, JString, required = false,
                                   default = nil)
  if valid_21626143 != nil:
    section.add "X-Amz-Security-Token", valid_21626143
  var valid_21626144 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626144 = validateParameter(valid_21626144, JString, required = false,
                                   default = nil)
  if valid_21626144 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626144
  var valid_21626145 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626145 = validateParameter(valid_21626145, JString, required = false,
                                   default = nil)
  if valid_21626145 != nil:
    section.add "X-Amz-Algorithm", valid_21626145
  var valid_21626146 = header.getOrDefault("X-Amz-Signature")
  valid_21626146 = validateParameter(valid_21626146, JString, required = false,
                                   default = nil)
  if valid_21626146 != nil:
    section.add "X-Amz-Signature", valid_21626146
  var valid_21626147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626147 = validateParameter(valid_21626147, JString, required = false,
                                   default = nil)
  if valid_21626147 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626147
  var valid_21626148 = header.getOrDefault("X-Amz-Credential")
  valid_21626148 = validateParameter(valid_21626148, JString, required = false,
                                   default = nil)
  if valid_21626148 != nil:
    section.add "X-Amz-Credential", valid_21626148
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626149: Call_ListDataSets_21626134; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Lists all of the datasets belonging to the current AWS account in an AWS Region.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:dataset/*</code>.</p>
  ## 
  let valid = call_21626149.validator(path, query, header, formData, body, _)
  let scheme = call_21626149.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626149.makeUrl(scheme.get, call_21626149.host, call_21626149.base,
                               call_21626149.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626149, uri, valid, _)

proc call*(call_21626150: Call_ListDataSets_21626134; AwsAccountId: string;
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listDataSets
  ## <p>Lists all of the datasets belonging to the current AWS account in an AWS Region.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:dataset/*</code>.</p>
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results to be returned per request.
  ##   nextToken: string
  ##            : The token for the next set of results, or null if there are no more results.
  ##   MaxResults: string
  ##             : Pagination limit
  var path_21626151 = newJObject()
  var query_21626152 = newJObject()
  add(path_21626151, "AwsAccountId", newJString(AwsAccountId))
  add(query_21626152, "NextToken", newJString(NextToken))
  add(query_21626152, "max-results", newJInt(maxResults))
  add(query_21626152, "next-token", newJString(nextToken))
  add(query_21626152, "MaxResults", newJString(MaxResults))
  result = call_21626150.call(path_21626151, query_21626152, nil, nil, nil)

var listDataSets* = Call_ListDataSets_21626134(name: "listDataSets",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sets", validator: validate_ListDataSets_21626135,
    base: "/", makeUrl: url_ListDataSets_21626136,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataSource_21626188 = ref object of OpenApiRestCall_21625435
proc url_CreateDataSource_21626190(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/data-sources")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateDataSource_21626189(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a data source.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_21626191 = path.getOrDefault("AwsAccountId")
  valid_21626191 = validateParameter(valid_21626191, JString, required = true,
                                   default = nil)
  if valid_21626191 != nil:
    section.add "AwsAccountId", valid_21626191
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626192 = header.getOrDefault("X-Amz-Date")
  valid_21626192 = validateParameter(valid_21626192, JString, required = false,
                                   default = nil)
  if valid_21626192 != nil:
    section.add "X-Amz-Date", valid_21626192
  var valid_21626193 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626193 = validateParameter(valid_21626193, JString, required = false,
                                   default = nil)
  if valid_21626193 != nil:
    section.add "X-Amz-Security-Token", valid_21626193
  var valid_21626194 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626194 = validateParameter(valid_21626194, JString, required = false,
                                   default = nil)
  if valid_21626194 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626194
  var valid_21626195 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626195 = validateParameter(valid_21626195, JString, required = false,
                                   default = nil)
  if valid_21626195 != nil:
    section.add "X-Amz-Algorithm", valid_21626195
  var valid_21626196 = header.getOrDefault("X-Amz-Signature")
  valid_21626196 = validateParameter(valid_21626196, JString, required = false,
                                   default = nil)
  if valid_21626196 != nil:
    section.add "X-Amz-Signature", valid_21626196
  var valid_21626197 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626197 = validateParameter(valid_21626197, JString, required = false,
                                   default = nil)
  if valid_21626197 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626197
  var valid_21626198 = header.getOrDefault("X-Amz-Credential")
  valid_21626198 = validateParameter(valid_21626198, JString, required = false,
                                   default = nil)
  if valid_21626198 != nil:
    section.add "X-Amz-Credential", valid_21626198
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626200: Call_CreateDataSource_21626188; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a data source.
  ## 
  let valid = call_21626200.validator(path, query, header, formData, body, _)
  let scheme = call_21626200.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626200.makeUrl(scheme.get, call_21626200.host, call_21626200.base,
                               call_21626200.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626200, uri, valid, _)

proc call*(call_21626201: Call_CreateDataSource_21626188; AwsAccountId: string;
          body: JsonNode): Recallable =
  ## createDataSource
  ## Creates a data source.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   body: JObject (required)
  var path_21626202 = newJObject()
  var body_21626203 = newJObject()
  add(path_21626202, "AwsAccountId", newJString(AwsAccountId))
  if body != nil:
    body_21626203 = body
  result = call_21626201.call(path_21626202, nil, nil, nil, body_21626203)

var createDataSource* = Call_CreateDataSource_21626188(name: "createDataSource",
    meth: HttpMethod.HttpPost, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sources",
    validator: validate_CreateDataSource_21626189, base: "/",
    makeUrl: url_CreateDataSource_21626190, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDataSources_21626169 = ref object of OpenApiRestCall_21625435
proc url_ListDataSources_21626171(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/data-sources")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListDataSources_21626170(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists data sources in current AWS Region that belong to this AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_21626172 = path.getOrDefault("AwsAccountId")
  valid_21626172 = validateParameter(valid_21626172, JString, required = true,
                                   default = nil)
  if valid_21626172 != nil:
    section.add "AwsAccountId", valid_21626172
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   max-results: JInt
  ##              : The maximum number of results to be returned per request.
  ##   next-token: JString
  ##             : The token for the next set of results, or null if there are no more results.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626173 = query.getOrDefault("NextToken")
  valid_21626173 = validateParameter(valid_21626173, JString, required = false,
                                   default = nil)
  if valid_21626173 != nil:
    section.add "NextToken", valid_21626173
  var valid_21626174 = query.getOrDefault("max-results")
  valid_21626174 = validateParameter(valid_21626174, JInt, required = false,
                                   default = nil)
  if valid_21626174 != nil:
    section.add "max-results", valid_21626174
  var valid_21626175 = query.getOrDefault("next-token")
  valid_21626175 = validateParameter(valid_21626175, JString, required = false,
                                   default = nil)
  if valid_21626175 != nil:
    section.add "next-token", valid_21626175
  var valid_21626176 = query.getOrDefault("MaxResults")
  valid_21626176 = validateParameter(valid_21626176, JString, required = false,
                                   default = nil)
  if valid_21626176 != nil:
    section.add "MaxResults", valid_21626176
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626177 = header.getOrDefault("X-Amz-Date")
  valid_21626177 = validateParameter(valid_21626177, JString, required = false,
                                   default = nil)
  if valid_21626177 != nil:
    section.add "X-Amz-Date", valid_21626177
  var valid_21626178 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626178 = validateParameter(valid_21626178, JString, required = false,
                                   default = nil)
  if valid_21626178 != nil:
    section.add "X-Amz-Security-Token", valid_21626178
  var valid_21626179 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626179 = validateParameter(valid_21626179, JString, required = false,
                                   default = nil)
  if valid_21626179 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626179
  var valid_21626180 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626180 = validateParameter(valid_21626180, JString, required = false,
                                   default = nil)
  if valid_21626180 != nil:
    section.add "X-Amz-Algorithm", valid_21626180
  var valid_21626181 = header.getOrDefault("X-Amz-Signature")
  valid_21626181 = validateParameter(valid_21626181, JString, required = false,
                                   default = nil)
  if valid_21626181 != nil:
    section.add "X-Amz-Signature", valid_21626181
  var valid_21626182 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626182 = validateParameter(valid_21626182, JString, required = false,
                                   default = nil)
  if valid_21626182 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626182
  var valid_21626183 = header.getOrDefault("X-Amz-Credential")
  valid_21626183 = validateParameter(valid_21626183, JString, required = false,
                                   default = nil)
  if valid_21626183 != nil:
    section.add "X-Amz-Credential", valid_21626183
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626184: Call_ListDataSources_21626169; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists data sources in current AWS Region that belong to this AWS account.
  ## 
  let valid = call_21626184.validator(path, query, header, formData, body, _)
  let scheme = call_21626184.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626184.makeUrl(scheme.get, call_21626184.host, call_21626184.base,
                               call_21626184.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626184, uri, valid, _)

proc call*(call_21626185: Call_ListDataSources_21626169; AwsAccountId: string;
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listDataSources
  ## Lists data sources in current AWS Region that belong to this AWS account.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results to be returned per request.
  ##   nextToken: string
  ##            : The token for the next set of results, or null if there are no more results.
  ##   MaxResults: string
  ##             : Pagination limit
  var path_21626186 = newJObject()
  var query_21626187 = newJObject()
  add(path_21626186, "AwsAccountId", newJString(AwsAccountId))
  add(query_21626187, "NextToken", newJString(NextToken))
  add(query_21626187, "max-results", newJInt(maxResults))
  add(query_21626187, "next-token", newJString(nextToken))
  add(query_21626187, "MaxResults", newJString(MaxResults))
  result = call_21626185.call(path_21626186, query_21626187, nil, nil, nil)

var listDataSources* = Call_ListDataSources_21626169(name: "listDataSources",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sources",
    validator: validate_ListDataSources_21626170, base: "/",
    makeUrl: url_ListDataSources_21626171, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGroup_21626222 = ref object of OpenApiRestCall_21625435
proc url_CreateGroup_21626224(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "Namespace" in path, "`Namespace` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/namespaces/"),
               (kind: VariableSegment, value: "Namespace"),
               (kind: ConstantSegment, value: "/groups")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateGroup_21626223(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates an Amazon QuickSight group.</p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;relevant-aws-account-id&gt;</i>:group/default/<i>&lt;group-name&gt;</i> </code>.</p> <p>The response is a group object.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_21626225 = path.getOrDefault("AwsAccountId")
  valid_21626225 = validateParameter(valid_21626225, JString, required = true,
                                   default = nil)
  if valid_21626225 != nil:
    section.add "AwsAccountId", valid_21626225
  var valid_21626226 = path.getOrDefault("Namespace")
  valid_21626226 = validateParameter(valid_21626226, JString, required = true,
                                   default = nil)
  if valid_21626226 != nil:
    section.add "Namespace", valid_21626226
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626227 = header.getOrDefault("X-Amz-Date")
  valid_21626227 = validateParameter(valid_21626227, JString, required = false,
                                   default = nil)
  if valid_21626227 != nil:
    section.add "X-Amz-Date", valid_21626227
  var valid_21626228 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626228 = validateParameter(valid_21626228, JString, required = false,
                                   default = nil)
  if valid_21626228 != nil:
    section.add "X-Amz-Security-Token", valid_21626228
  var valid_21626229 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626229 = validateParameter(valid_21626229, JString, required = false,
                                   default = nil)
  if valid_21626229 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626229
  var valid_21626230 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626230 = validateParameter(valid_21626230, JString, required = false,
                                   default = nil)
  if valid_21626230 != nil:
    section.add "X-Amz-Algorithm", valid_21626230
  var valid_21626231 = header.getOrDefault("X-Amz-Signature")
  valid_21626231 = validateParameter(valid_21626231, JString, required = false,
                                   default = nil)
  if valid_21626231 != nil:
    section.add "X-Amz-Signature", valid_21626231
  var valid_21626232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626232 = validateParameter(valid_21626232, JString, required = false,
                                   default = nil)
  if valid_21626232 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626232
  var valid_21626233 = header.getOrDefault("X-Amz-Credential")
  valid_21626233 = validateParameter(valid_21626233, JString, required = false,
                                   default = nil)
  if valid_21626233 != nil:
    section.add "X-Amz-Credential", valid_21626233
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626235: Call_CreateGroup_21626222; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates an Amazon QuickSight group.</p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;relevant-aws-account-id&gt;</i>:group/default/<i>&lt;group-name&gt;</i> </code>.</p> <p>The response is a group object.</p>
  ## 
  let valid = call_21626235.validator(path, query, header, formData, body, _)
  let scheme = call_21626235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626235.makeUrl(scheme.get, call_21626235.host, call_21626235.base,
                               call_21626235.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626235, uri, valid, _)

proc call*(call_21626236: Call_CreateGroup_21626222; AwsAccountId: string;
          body: JsonNode; Namespace: string): Recallable =
  ## createGroup
  ## <p>Creates an Amazon QuickSight group.</p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;relevant-aws-account-id&gt;</i>:group/default/<i>&lt;group-name&gt;</i> </code>.</p> <p>The response is a group object.</p>
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   body: JObject (required)
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  var path_21626237 = newJObject()
  var body_21626238 = newJObject()
  add(path_21626237, "AwsAccountId", newJString(AwsAccountId))
  if body != nil:
    body_21626238 = body
  add(path_21626237, "Namespace", newJString(Namespace))
  result = call_21626236.call(path_21626237, nil, nil, nil, body_21626238)

var createGroup* = Call_CreateGroup_21626222(name: "createGroup",
    meth: HttpMethod.HttpPost, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups",
    validator: validate_CreateGroup_21626223, base: "/", makeUrl: url_CreateGroup_21626224,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroups_21626204 = ref object of OpenApiRestCall_21625435
proc url_ListGroups_21626206(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "Namespace" in path, "`Namespace` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/namespaces/"),
               (kind: VariableSegment, value: "Namespace"),
               (kind: ConstantSegment, value: "/groups")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListGroups_21626205(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists all user groups in Amazon QuickSight. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_21626207 = path.getOrDefault("AwsAccountId")
  valid_21626207 = validateParameter(valid_21626207, JString, required = true,
                                   default = nil)
  if valid_21626207 != nil:
    section.add "AwsAccountId", valid_21626207
  var valid_21626208 = path.getOrDefault("Namespace")
  valid_21626208 = validateParameter(valid_21626208, JString, required = true,
                                   default = nil)
  if valid_21626208 != nil:
    section.add "Namespace", valid_21626208
  result.add "path", section
  ## parameters in `query` object:
  ##   max-results: JInt
  ##              : The maximum number of results to return.
  ##   next-token: JString
  ##             : A pagination token that can be used in a subsequent request.
  section = newJObject()
  var valid_21626209 = query.getOrDefault("max-results")
  valid_21626209 = validateParameter(valid_21626209, JInt, required = false,
                                   default = nil)
  if valid_21626209 != nil:
    section.add "max-results", valid_21626209
  var valid_21626210 = query.getOrDefault("next-token")
  valid_21626210 = validateParameter(valid_21626210, JString, required = false,
                                   default = nil)
  if valid_21626210 != nil:
    section.add "next-token", valid_21626210
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626211 = header.getOrDefault("X-Amz-Date")
  valid_21626211 = validateParameter(valid_21626211, JString, required = false,
                                   default = nil)
  if valid_21626211 != nil:
    section.add "X-Amz-Date", valid_21626211
  var valid_21626212 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626212 = validateParameter(valid_21626212, JString, required = false,
                                   default = nil)
  if valid_21626212 != nil:
    section.add "X-Amz-Security-Token", valid_21626212
  var valid_21626213 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626213 = validateParameter(valid_21626213, JString, required = false,
                                   default = nil)
  if valid_21626213 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626213
  var valid_21626214 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626214 = validateParameter(valid_21626214, JString, required = false,
                                   default = nil)
  if valid_21626214 != nil:
    section.add "X-Amz-Algorithm", valid_21626214
  var valid_21626215 = header.getOrDefault("X-Amz-Signature")
  valid_21626215 = validateParameter(valid_21626215, JString, required = false,
                                   default = nil)
  if valid_21626215 != nil:
    section.add "X-Amz-Signature", valid_21626215
  var valid_21626216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626216 = validateParameter(valid_21626216, JString, required = false,
                                   default = nil)
  if valid_21626216 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626216
  var valid_21626217 = header.getOrDefault("X-Amz-Credential")
  valid_21626217 = validateParameter(valid_21626217, JString, required = false,
                                   default = nil)
  if valid_21626217 != nil:
    section.add "X-Amz-Credential", valid_21626217
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626218: Call_ListGroups_21626204; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all user groups in Amazon QuickSight. 
  ## 
  let valid = call_21626218.validator(path, query, header, formData, body, _)
  let scheme = call_21626218.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626218.makeUrl(scheme.get, call_21626218.host, call_21626218.base,
                               call_21626218.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626218, uri, valid, _)

proc call*(call_21626219: Call_ListGroups_21626204; AwsAccountId: string;
          Namespace: string; maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listGroups
  ## Lists all user groups in Amazon QuickSight. 
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   maxResults: int
  ##             : The maximum number of results to return.
  ##   nextToken: string
  ##            : A pagination token that can be used in a subsequent request.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  var path_21626220 = newJObject()
  var query_21626221 = newJObject()
  add(path_21626220, "AwsAccountId", newJString(AwsAccountId))
  add(query_21626221, "max-results", newJInt(maxResults))
  add(query_21626221, "next-token", newJString(nextToken))
  add(path_21626220, "Namespace", newJString(Namespace))
  result = call_21626219.call(path_21626220, query_21626221, nil, nil, nil)

var listGroups* = Call_ListGroups_21626204(name: "listGroups",
                                        meth: HttpMethod.HttpGet,
                                        host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups",
                                        validator: validate_ListGroups_21626205,
                                        base: "/", makeUrl: url_ListGroups_21626206,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGroupMembership_21626239 = ref object of OpenApiRestCall_21625435
proc url_CreateGroupMembership_21626241(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "Namespace" in path, "`Namespace` is a required path parameter"
  assert "GroupName" in path, "`GroupName` is a required path parameter"
  assert "MemberName" in path, "`MemberName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/namespaces/"),
               (kind: VariableSegment, value: "Namespace"),
               (kind: ConstantSegment, value: "/groups/"),
               (kind: VariableSegment, value: "GroupName"),
               (kind: ConstantSegment, value: "/members/"),
               (kind: VariableSegment, value: "MemberName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateGroupMembership_21626240(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Adds an Amazon QuickSight user to an Amazon QuickSight group. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupName: JString (required)
  ##            : The name of the group that you want to add the user to.
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   MemberName: JString (required)
  ##             : The name of the user that you want to add to the group membership.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupName` field"
  var valid_21626242 = path.getOrDefault("GroupName")
  valid_21626242 = validateParameter(valid_21626242, JString, required = true,
                                   default = nil)
  if valid_21626242 != nil:
    section.add "GroupName", valid_21626242
  var valid_21626243 = path.getOrDefault("AwsAccountId")
  valid_21626243 = validateParameter(valid_21626243, JString, required = true,
                                   default = nil)
  if valid_21626243 != nil:
    section.add "AwsAccountId", valid_21626243
  var valid_21626244 = path.getOrDefault("MemberName")
  valid_21626244 = validateParameter(valid_21626244, JString, required = true,
                                   default = nil)
  if valid_21626244 != nil:
    section.add "MemberName", valid_21626244
  var valid_21626245 = path.getOrDefault("Namespace")
  valid_21626245 = validateParameter(valid_21626245, JString, required = true,
                                   default = nil)
  if valid_21626245 != nil:
    section.add "Namespace", valid_21626245
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626246 = header.getOrDefault("X-Amz-Date")
  valid_21626246 = validateParameter(valid_21626246, JString, required = false,
                                   default = nil)
  if valid_21626246 != nil:
    section.add "X-Amz-Date", valid_21626246
  var valid_21626247 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626247 = validateParameter(valid_21626247, JString, required = false,
                                   default = nil)
  if valid_21626247 != nil:
    section.add "X-Amz-Security-Token", valid_21626247
  var valid_21626248 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626248 = validateParameter(valid_21626248, JString, required = false,
                                   default = nil)
  if valid_21626248 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626248
  var valid_21626249 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626249 = validateParameter(valid_21626249, JString, required = false,
                                   default = nil)
  if valid_21626249 != nil:
    section.add "X-Amz-Algorithm", valid_21626249
  var valid_21626250 = header.getOrDefault("X-Amz-Signature")
  valid_21626250 = validateParameter(valid_21626250, JString, required = false,
                                   default = nil)
  if valid_21626250 != nil:
    section.add "X-Amz-Signature", valid_21626250
  var valid_21626251 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626251 = validateParameter(valid_21626251, JString, required = false,
                                   default = nil)
  if valid_21626251 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626251
  var valid_21626252 = header.getOrDefault("X-Amz-Credential")
  valid_21626252 = validateParameter(valid_21626252, JString, required = false,
                                   default = nil)
  if valid_21626252 != nil:
    section.add "X-Amz-Credential", valid_21626252
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626253: Call_CreateGroupMembership_21626239;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds an Amazon QuickSight user to an Amazon QuickSight group. 
  ## 
  let valid = call_21626253.validator(path, query, header, formData, body, _)
  let scheme = call_21626253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626253.makeUrl(scheme.get, call_21626253.host, call_21626253.base,
                               call_21626253.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626253, uri, valid, _)

proc call*(call_21626254: Call_CreateGroupMembership_21626239; GroupName: string;
          AwsAccountId: string; MemberName: string; Namespace: string): Recallable =
  ## createGroupMembership
  ## Adds an Amazon QuickSight user to an Amazon QuickSight group. 
  ##   GroupName: string (required)
  ##            : The name of the group that you want to add the user to.
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   MemberName: string (required)
  ##             : The name of the user that you want to add to the group membership.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  var path_21626255 = newJObject()
  add(path_21626255, "GroupName", newJString(GroupName))
  add(path_21626255, "AwsAccountId", newJString(AwsAccountId))
  add(path_21626255, "MemberName", newJString(MemberName))
  add(path_21626255, "Namespace", newJString(Namespace))
  result = call_21626254.call(path_21626255, nil, nil, nil, nil)

var createGroupMembership* = Call_CreateGroupMembership_21626239(
    name: "createGroupMembership", meth: HttpMethod.HttpPut,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}/members/{MemberName}",
    validator: validate_CreateGroupMembership_21626240, base: "/",
    makeUrl: url_CreateGroupMembership_21626241,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGroupMembership_21626256 = ref object of OpenApiRestCall_21625435
proc url_DeleteGroupMembership_21626258(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "Namespace" in path, "`Namespace` is a required path parameter"
  assert "GroupName" in path, "`GroupName` is a required path parameter"
  assert "MemberName" in path, "`MemberName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/namespaces/"),
               (kind: VariableSegment, value: "Namespace"),
               (kind: ConstantSegment, value: "/groups/"),
               (kind: VariableSegment, value: "GroupName"),
               (kind: ConstantSegment, value: "/members/"),
               (kind: VariableSegment, value: "MemberName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteGroupMembership_21626257(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Removes a user from a group so that the user is no longer a member of the group.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupName: JString (required)
  ##            : The name of the group that you want to delete the user from.
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   MemberName: JString (required)
  ##             : The name of the user that you want to delete from the group membership.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupName` field"
  var valid_21626259 = path.getOrDefault("GroupName")
  valid_21626259 = validateParameter(valid_21626259, JString, required = true,
                                   default = nil)
  if valid_21626259 != nil:
    section.add "GroupName", valid_21626259
  var valid_21626260 = path.getOrDefault("AwsAccountId")
  valid_21626260 = validateParameter(valid_21626260, JString, required = true,
                                   default = nil)
  if valid_21626260 != nil:
    section.add "AwsAccountId", valid_21626260
  var valid_21626261 = path.getOrDefault("MemberName")
  valid_21626261 = validateParameter(valid_21626261, JString, required = true,
                                   default = nil)
  if valid_21626261 != nil:
    section.add "MemberName", valid_21626261
  var valid_21626262 = path.getOrDefault("Namespace")
  valid_21626262 = validateParameter(valid_21626262, JString, required = true,
                                   default = nil)
  if valid_21626262 != nil:
    section.add "Namespace", valid_21626262
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626263 = header.getOrDefault("X-Amz-Date")
  valid_21626263 = validateParameter(valid_21626263, JString, required = false,
                                   default = nil)
  if valid_21626263 != nil:
    section.add "X-Amz-Date", valid_21626263
  var valid_21626264 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626264 = validateParameter(valid_21626264, JString, required = false,
                                   default = nil)
  if valid_21626264 != nil:
    section.add "X-Amz-Security-Token", valid_21626264
  var valid_21626265 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626265 = validateParameter(valid_21626265, JString, required = false,
                                   default = nil)
  if valid_21626265 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626265
  var valid_21626266 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626266 = validateParameter(valid_21626266, JString, required = false,
                                   default = nil)
  if valid_21626266 != nil:
    section.add "X-Amz-Algorithm", valid_21626266
  var valid_21626267 = header.getOrDefault("X-Amz-Signature")
  valid_21626267 = validateParameter(valid_21626267, JString, required = false,
                                   default = nil)
  if valid_21626267 != nil:
    section.add "X-Amz-Signature", valid_21626267
  var valid_21626268 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626268 = validateParameter(valid_21626268, JString, required = false,
                                   default = nil)
  if valid_21626268 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626268
  var valid_21626269 = header.getOrDefault("X-Amz-Credential")
  valid_21626269 = validateParameter(valid_21626269, JString, required = false,
                                   default = nil)
  if valid_21626269 != nil:
    section.add "X-Amz-Credential", valid_21626269
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626270: Call_DeleteGroupMembership_21626256;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes a user from a group so that the user is no longer a member of the group.
  ## 
  let valid = call_21626270.validator(path, query, header, formData, body, _)
  let scheme = call_21626270.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626270.makeUrl(scheme.get, call_21626270.host, call_21626270.base,
                               call_21626270.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626270, uri, valid, _)

proc call*(call_21626271: Call_DeleteGroupMembership_21626256; GroupName: string;
          AwsAccountId: string; MemberName: string; Namespace: string): Recallable =
  ## deleteGroupMembership
  ## Removes a user from a group so that the user is no longer a member of the group.
  ##   GroupName: string (required)
  ##            : The name of the group that you want to delete the user from.
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   MemberName: string (required)
  ##             : The name of the user that you want to delete from the group membership.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  var path_21626272 = newJObject()
  add(path_21626272, "GroupName", newJString(GroupName))
  add(path_21626272, "AwsAccountId", newJString(AwsAccountId))
  add(path_21626272, "MemberName", newJString(MemberName))
  add(path_21626272, "Namespace", newJString(Namespace))
  result = call_21626271.call(path_21626272, nil, nil, nil, nil)

var deleteGroupMembership* = Call_DeleteGroupMembership_21626256(
    name: "deleteGroupMembership", meth: HttpMethod.HttpDelete,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}/members/{MemberName}",
    validator: validate_DeleteGroupMembership_21626257, base: "/",
    makeUrl: url_DeleteGroupMembership_21626258,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIAMPolicyAssignment_21626273 = ref object of OpenApiRestCall_21625435
proc url_CreateIAMPolicyAssignment_21626275(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "Namespace" in path, "`Namespace` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/namespaces/"),
               (kind: VariableSegment, value: "Namespace"),
               (kind: ConstantSegment, value: "/iam-policy-assignments/")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateIAMPolicyAssignment_21626274(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates an assignment with one specified IAM policy, identified by its Amazon Resource Name (ARN). This policy will be assigned to specified groups or users of Amazon QuickSight. The users and groups need to be in the same namespace. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account where you want to assign an IAM policy to QuickSight users or groups.
  ##   Namespace: JString (required)
  ##            : The namespace that contains the assignment.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_21626276 = path.getOrDefault("AwsAccountId")
  valid_21626276 = validateParameter(valid_21626276, JString, required = true,
                                   default = nil)
  if valid_21626276 != nil:
    section.add "AwsAccountId", valid_21626276
  var valid_21626277 = path.getOrDefault("Namespace")
  valid_21626277 = validateParameter(valid_21626277, JString, required = true,
                                   default = nil)
  if valid_21626277 != nil:
    section.add "Namespace", valid_21626277
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626278 = header.getOrDefault("X-Amz-Date")
  valid_21626278 = validateParameter(valid_21626278, JString, required = false,
                                   default = nil)
  if valid_21626278 != nil:
    section.add "X-Amz-Date", valid_21626278
  var valid_21626279 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626279 = validateParameter(valid_21626279, JString, required = false,
                                   default = nil)
  if valid_21626279 != nil:
    section.add "X-Amz-Security-Token", valid_21626279
  var valid_21626280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626280 = validateParameter(valid_21626280, JString, required = false,
                                   default = nil)
  if valid_21626280 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626280
  var valid_21626281 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626281 = validateParameter(valid_21626281, JString, required = false,
                                   default = nil)
  if valid_21626281 != nil:
    section.add "X-Amz-Algorithm", valid_21626281
  var valid_21626282 = header.getOrDefault("X-Amz-Signature")
  valid_21626282 = validateParameter(valid_21626282, JString, required = false,
                                   default = nil)
  if valid_21626282 != nil:
    section.add "X-Amz-Signature", valid_21626282
  var valid_21626283 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626283 = validateParameter(valid_21626283, JString, required = false,
                                   default = nil)
  if valid_21626283 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626283
  var valid_21626284 = header.getOrDefault("X-Amz-Credential")
  valid_21626284 = validateParameter(valid_21626284, JString, required = false,
                                   default = nil)
  if valid_21626284 != nil:
    section.add "X-Amz-Credential", valid_21626284
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626286: Call_CreateIAMPolicyAssignment_21626273;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an assignment with one specified IAM policy, identified by its Amazon Resource Name (ARN). This policy will be assigned to specified groups or users of Amazon QuickSight. The users and groups need to be in the same namespace. 
  ## 
  let valid = call_21626286.validator(path, query, header, formData, body, _)
  let scheme = call_21626286.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626286.makeUrl(scheme.get, call_21626286.host, call_21626286.base,
                               call_21626286.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626286, uri, valid, _)

proc call*(call_21626287: Call_CreateIAMPolicyAssignment_21626273;
          AwsAccountId: string; body: JsonNode; Namespace: string): Recallable =
  ## createIAMPolicyAssignment
  ## Creates an assignment with one specified IAM policy, identified by its Amazon Resource Name (ARN). This policy will be assigned to specified groups or users of Amazon QuickSight. The users and groups need to be in the same namespace. 
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account where you want to assign an IAM policy to QuickSight users or groups.
  ##   body: JObject (required)
  ##   Namespace: string (required)
  ##            : The namespace that contains the assignment.
  var path_21626288 = newJObject()
  var body_21626289 = newJObject()
  add(path_21626288, "AwsAccountId", newJString(AwsAccountId))
  if body != nil:
    body_21626289 = body
  add(path_21626288, "Namespace", newJString(Namespace))
  result = call_21626287.call(path_21626288, nil, nil, nil, body_21626289)

var createIAMPolicyAssignment* = Call_CreateIAMPolicyAssignment_21626273(
    name: "createIAMPolicyAssignment", meth: HttpMethod.HttpPost,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/iam-policy-assignments/",
    validator: validate_CreateIAMPolicyAssignment_21626274, base: "/",
    makeUrl: url_CreateIAMPolicyAssignment_21626275,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTemplate_21626308 = ref object of OpenApiRestCall_21625435
proc url_UpdateTemplate_21626310(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "TemplateId" in path, "`TemplateId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/templates/"),
               (kind: VariableSegment, value: "TemplateId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateTemplate_21626309(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates a template from an existing Amazon QuickSight analysis or another template.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account that contains the template that you're updating.
  ##   TemplateId: JString (required)
  ##             : The ID for the template.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_21626311 = path.getOrDefault("AwsAccountId")
  valid_21626311 = validateParameter(valid_21626311, JString, required = true,
                                   default = nil)
  if valid_21626311 != nil:
    section.add "AwsAccountId", valid_21626311
  var valid_21626312 = path.getOrDefault("TemplateId")
  valid_21626312 = validateParameter(valid_21626312, JString, required = true,
                                   default = nil)
  if valid_21626312 != nil:
    section.add "TemplateId", valid_21626312
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626313 = header.getOrDefault("X-Amz-Date")
  valid_21626313 = validateParameter(valid_21626313, JString, required = false,
                                   default = nil)
  if valid_21626313 != nil:
    section.add "X-Amz-Date", valid_21626313
  var valid_21626314 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626314 = validateParameter(valid_21626314, JString, required = false,
                                   default = nil)
  if valid_21626314 != nil:
    section.add "X-Amz-Security-Token", valid_21626314
  var valid_21626315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626315 = validateParameter(valid_21626315, JString, required = false,
                                   default = nil)
  if valid_21626315 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626315
  var valid_21626316 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626316 = validateParameter(valid_21626316, JString, required = false,
                                   default = nil)
  if valid_21626316 != nil:
    section.add "X-Amz-Algorithm", valid_21626316
  var valid_21626317 = header.getOrDefault("X-Amz-Signature")
  valid_21626317 = validateParameter(valid_21626317, JString, required = false,
                                   default = nil)
  if valid_21626317 != nil:
    section.add "X-Amz-Signature", valid_21626317
  var valid_21626318 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626318 = validateParameter(valid_21626318, JString, required = false,
                                   default = nil)
  if valid_21626318 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626318
  var valid_21626319 = header.getOrDefault("X-Amz-Credential")
  valid_21626319 = validateParameter(valid_21626319, JString, required = false,
                                   default = nil)
  if valid_21626319 != nil:
    section.add "X-Amz-Credential", valid_21626319
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626321: Call_UpdateTemplate_21626308; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a template from an existing Amazon QuickSight analysis or another template.
  ## 
  let valid = call_21626321.validator(path, query, header, formData, body, _)
  let scheme = call_21626321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626321.makeUrl(scheme.get, call_21626321.host, call_21626321.base,
                               call_21626321.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626321, uri, valid, _)

proc call*(call_21626322: Call_UpdateTemplate_21626308; AwsAccountId: string;
          TemplateId: string; body: JsonNode): Recallable =
  ## updateTemplate
  ## Updates a template from an existing Amazon QuickSight analysis or another template.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the template that you're updating.
  ##   TemplateId: string (required)
  ##             : The ID for the template.
  ##   body: JObject (required)
  var path_21626323 = newJObject()
  var body_21626324 = newJObject()
  add(path_21626323, "AwsAccountId", newJString(AwsAccountId))
  add(path_21626323, "TemplateId", newJString(TemplateId))
  if body != nil:
    body_21626324 = body
  result = call_21626322.call(path_21626323, nil, nil, nil, body_21626324)

var updateTemplate* = Call_UpdateTemplate_21626308(name: "updateTemplate",
    meth: HttpMethod.HttpPut, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates/{TemplateId}",
    validator: validate_UpdateTemplate_21626309, base: "/",
    makeUrl: url_UpdateTemplate_21626310, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTemplate_21626325 = ref object of OpenApiRestCall_21625435
proc url_CreateTemplate_21626327(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "TemplateId" in path, "`TemplateId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/templates/"),
               (kind: VariableSegment, value: "TemplateId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateTemplate_21626326(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a template from an existing QuickSight analysis or template. You can use the resulting template to create a dashboard.</p> <p>A <i>template</i> is an entity in QuickSight that encapsulates the metadata required to create an analysis and that you can use to create s dashboard. A template adds a layer of abstraction by using placeholders to replace the dataset associated with the analysis. You can use templates to create dashboards by replacing dataset placeholders with datasets that follow the same schema that was used to create the source analysis and template.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   TemplateId: JString (required)
  ##             : An ID for the template that you want to create. This template is unique per AWS Region in each AWS account.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_21626328 = path.getOrDefault("AwsAccountId")
  valid_21626328 = validateParameter(valid_21626328, JString, required = true,
                                   default = nil)
  if valid_21626328 != nil:
    section.add "AwsAccountId", valid_21626328
  var valid_21626329 = path.getOrDefault("TemplateId")
  valid_21626329 = validateParameter(valid_21626329, JString, required = true,
                                   default = nil)
  if valid_21626329 != nil:
    section.add "TemplateId", valid_21626329
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626330 = header.getOrDefault("X-Amz-Date")
  valid_21626330 = validateParameter(valid_21626330, JString, required = false,
                                   default = nil)
  if valid_21626330 != nil:
    section.add "X-Amz-Date", valid_21626330
  var valid_21626331 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626331 = validateParameter(valid_21626331, JString, required = false,
                                   default = nil)
  if valid_21626331 != nil:
    section.add "X-Amz-Security-Token", valid_21626331
  var valid_21626332 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626332 = validateParameter(valid_21626332, JString, required = false,
                                   default = nil)
  if valid_21626332 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626332
  var valid_21626333 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626333 = validateParameter(valid_21626333, JString, required = false,
                                   default = nil)
  if valid_21626333 != nil:
    section.add "X-Amz-Algorithm", valid_21626333
  var valid_21626334 = header.getOrDefault("X-Amz-Signature")
  valid_21626334 = validateParameter(valid_21626334, JString, required = false,
                                   default = nil)
  if valid_21626334 != nil:
    section.add "X-Amz-Signature", valid_21626334
  var valid_21626335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626335 = validateParameter(valid_21626335, JString, required = false,
                                   default = nil)
  if valid_21626335 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626335
  var valid_21626336 = header.getOrDefault("X-Amz-Credential")
  valid_21626336 = validateParameter(valid_21626336, JString, required = false,
                                   default = nil)
  if valid_21626336 != nil:
    section.add "X-Amz-Credential", valid_21626336
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626338: Call_CreateTemplate_21626325; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a template from an existing QuickSight analysis or template. You can use the resulting template to create a dashboard.</p> <p>A <i>template</i> is an entity in QuickSight that encapsulates the metadata required to create an analysis and that you can use to create s dashboard. A template adds a layer of abstraction by using placeholders to replace the dataset associated with the analysis. You can use templates to create dashboards by replacing dataset placeholders with datasets that follow the same schema that was used to create the source analysis and template.</p>
  ## 
  let valid = call_21626338.validator(path, query, header, formData, body, _)
  let scheme = call_21626338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626338.makeUrl(scheme.get, call_21626338.host, call_21626338.base,
                               call_21626338.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626338, uri, valid, _)

proc call*(call_21626339: Call_CreateTemplate_21626325; AwsAccountId: string;
          TemplateId: string; body: JsonNode): Recallable =
  ## createTemplate
  ## <p>Creates a template from an existing QuickSight analysis or template. You can use the resulting template to create a dashboard.</p> <p>A <i>template</i> is an entity in QuickSight that encapsulates the metadata required to create an analysis and that you can use to create s dashboard. A template adds a layer of abstraction by using placeholders to replace the dataset associated with the analysis. You can use templates to create dashboards by replacing dataset placeholders with datasets that follow the same schema that was used to create the source analysis and template.</p>
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   TemplateId: string (required)
  ##             : An ID for the template that you want to create. This template is unique per AWS Region in each AWS account.
  ##   body: JObject (required)
  var path_21626340 = newJObject()
  var body_21626341 = newJObject()
  add(path_21626340, "AwsAccountId", newJString(AwsAccountId))
  add(path_21626340, "TemplateId", newJString(TemplateId))
  if body != nil:
    body_21626341 = body
  result = call_21626339.call(path_21626340, nil, nil, nil, body_21626341)

var createTemplate* = Call_CreateTemplate_21626325(name: "createTemplate",
    meth: HttpMethod.HttpPost, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates/{TemplateId}",
    validator: validate_CreateTemplate_21626326, base: "/",
    makeUrl: url_CreateTemplate_21626327, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTemplate_21626290 = ref object of OpenApiRestCall_21625435
proc url_DescribeTemplate_21626292(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "TemplateId" in path, "`TemplateId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/templates/"),
               (kind: VariableSegment, value: "TemplateId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeTemplate_21626291(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Describes a template's metadata.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account that contains the template that you're describing.
  ##   TemplateId: JString (required)
  ##             : The ID for the template.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_21626293 = path.getOrDefault("AwsAccountId")
  valid_21626293 = validateParameter(valid_21626293, JString, required = true,
                                   default = nil)
  if valid_21626293 != nil:
    section.add "AwsAccountId", valid_21626293
  var valid_21626294 = path.getOrDefault("TemplateId")
  valid_21626294 = validateParameter(valid_21626294, JString, required = true,
                                   default = nil)
  if valid_21626294 != nil:
    section.add "TemplateId", valid_21626294
  result.add "path", section
  ## parameters in `query` object:
  ##   alias-name: JString
  ##             : The alias of the template that you want to describe. If you name a specific alias, you describe the version that the alias points to. You can specify the latest version of the template by providing the keyword <code>$LATEST</code> in the <code>AliasName</code> parameter. The keyword <code>$PUBLISHED</code> doesn't apply to templates.
  ##   version-number: JInt
  ##                 : (Optional) The number for the version to describe. If a <code>VersionNumber</code> parameter value isn't provided, the latest version of the template is described.
  section = newJObject()
  var valid_21626295 = query.getOrDefault("alias-name")
  valid_21626295 = validateParameter(valid_21626295, JString, required = false,
                                   default = nil)
  if valid_21626295 != nil:
    section.add "alias-name", valid_21626295
  var valid_21626296 = query.getOrDefault("version-number")
  valid_21626296 = validateParameter(valid_21626296, JInt, required = false,
                                   default = nil)
  if valid_21626296 != nil:
    section.add "version-number", valid_21626296
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626297 = header.getOrDefault("X-Amz-Date")
  valid_21626297 = validateParameter(valid_21626297, JString, required = false,
                                   default = nil)
  if valid_21626297 != nil:
    section.add "X-Amz-Date", valid_21626297
  var valid_21626298 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626298 = validateParameter(valid_21626298, JString, required = false,
                                   default = nil)
  if valid_21626298 != nil:
    section.add "X-Amz-Security-Token", valid_21626298
  var valid_21626299 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626299 = validateParameter(valid_21626299, JString, required = false,
                                   default = nil)
  if valid_21626299 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626299
  var valid_21626300 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626300 = validateParameter(valid_21626300, JString, required = false,
                                   default = nil)
  if valid_21626300 != nil:
    section.add "X-Amz-Algorithm", valid_21626300
  var valid_21626301 = header.getOrDefault("X-Amz-Signature")
  valid_21626301 = validateParameter(valid_21626301, JString, required = false,
                                   default = nil)
  if valid_21626301 != nil:
    section.add "X-Amz-Signature", valid_21626301
  var valid_21626302 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626302 = validateParameter(valid_21626302, JString, required = false,
                                   default = nil)
  if valid_21626302 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626302
  var valid_21626303 = header.getOrDefault("X-Amz-Credential")
  valid_21626303 = validateParameter(valid_21626303, JString, required = false,
                                   default = nil)
  if valid_21626303 != nil:
    section.add "X-Amz-Credential", valid_21626303
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626304: Call_DescribeTemplate_21626290; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes a template's metadata.
  ## 
  let valid = call_21626304.validator(path, query, header, formData, body, _)
  let scheme = call_21626304.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626304.makeUrl(scheme.get, call_21626304.host, call_21626304.base,
                               call_21626304.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626304, uri, valid, _)

proc call*(call_21626305: Call_DescribeTemplate_21626290; AwsAccountId: string;
          TemplateId: string; aliasName: string = ""; versionNumber: int = 0): Recallable =
  ## describeTemplate
  ## Describes a template's metadata.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the template that you're describing.
  ##   TemplateId: string (required)
  ##             : The ID for the template.
  ##   aliasName: string
  ##            : The alias of the template that you want to describe. If you name a specific alias, you describe the version that the alias points to. You can specify the latest version of the template by providing the keyword <code>$LATEST</code> in the <code>AliasName</code> parameter. The keyword <code>$PUBLISHED</code> doesn't apply to templates.
  ##   versionNumber: int
  ##                : (Optional) The number for the version to describe. If a <code>VersionNumber</code> parameter value isn't provided, the latest version of the template is described.
  var path_21626306 = newJObject()
  var query_21626307 = newJObject()
  add(path_21626306, "AwsAccountId", newJString(AwsAccountId))
  add(path_21626306, "TemplateId", newJString(TemplateId))
  add(query_21626307, "alias-name", newJString(aliasName))
  add(query_21626307, "version-number", newJInt(versionNumber))
  result = call_21626305.call(path_21626306, query_21626307, nil, nil, nil)

var describeTemplate* = Call_DescribeTemplate_21626290(name: "describeTemplate",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates/{TemplateId}",
    validator: validate_DescribeTemplate_21626291, base: "/",
    makeUrl: url_DescribeTemplate_21626292, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTemplate_21626342 = ref object of OpenApiRestCall_21625435
proc url_DeleteTemplate_21626344(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "TemplateId" in path, "`TemplateId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/templates/"),
               (kind: VariableSegment, value: "TemplateId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteTemplate_21626343(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a template.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account that contains the template that you're deleting.
  ##   TemplateId: JString (required)
  ##             : An ID for the template you want to delete.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_21626345 = path.getOrDefault("AwsAccountId")
  valid_21626345 = validateParameter(valid_21626345, JString, required = true,
                                   default = nil)
  if valid_21626345 != nil:
    section.add "AwsAccountId", valid_21626345
  var valid_21626346 = path.getOrDefault("TemplateId")
  valid_21626346 = validateParameter(valid_21626346, JString, required = true,
                                   default = nil)
  if valid_21626346 != nil:
    section.add "TemplateId", valid_21626346
  result.add "path", section
  ## parameters in `query` object:
  ##   version-number: JInt
  ##                 : Specifies the version of the template that you want to delete. If you don't provide a version number, <code>DeleteTemplate</code> deletes all versions of the template. 
  section = newJObject()
  var valid_21626347 = query.getOrDefault("version-number")
  valid_21626347 = validateParameter(valid_21626347, JInt, required = false,
                                   default = nil)
  if valid_21626347 != nil:
    section.add "version-number", valid_21626347
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626348 = header.getOrDefault("X-Amz-Date")
  valid_21626348 = validateParameter(valid_21626348, JString, required = false,
                                   default = nil)
  if valid_21626348 != nil:
    section.add "X-Amz-Date", valid_21626348
  var valid_21626349 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626349 = validateParameter(valid_21626349, JString, required = false,
                                   default = nil)
  if valid_21626349 != nil:
    section.add "X-Amz-Security-Token", valid_21626349
  var valid_21626350 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626350 = validateParameter(valid_21626350, JString, required = false,
                                   default = nil)
  if valid_21626350 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626350
  var valid_21626351 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626351 = validateParameter(valid_21626351, JString, required = false,
                                   default = nil)
  if valid_21626351 != nil:
    section.add "X-Amz-Algorithm", valid_21626351
  var valid_21626352 = header.getOrDefault("X-Amz-Signature")
  valid_21626352 = validateParameter(valid_21626352, JString, required = false,
                                   default = nil)
  if valid_21626352 != nil:
    section.add "X-Amz-Signature", valid_21626352
  var valid_21626353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626353 = validateParameter(valid_21626353, JString, required = false,
                                   default = nil)
  if valid_21626353 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626353
  var valid_21626354 = header.getOrDefault("X-Amz-Credential")
  valid_21626354 = validateParameter(valid_21626354, JString, required = false,
                                   default = nil)
  if valid_21626354 != nil:
    section.add "X-Amz-Credential", valid_21626354
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626355: Call_DeleteTemplate_21626342; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a template.
  ## 
  let valid = call_21626355.validator(path, query, header, formData, body, _)
  let scheme = call_21626355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626355.makeUrl(scheme.get, call_21626355.host, call_21626355.base,
                               call_21626355.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626355, uri, valid, _)

proc call*(call_21626356: Call_DeleteTemplate_21626342; AwsAccountId: string;
          TemplateId: string; versionNumber: int = 0): Recallable =
  ## deleteTemplate
  ## Deletes a template.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the template that you're deleting.
  ##   TemplateId: string (required)
  ##             : An ID for the template you want to delete.
  ##   versionNumber: int
  ##                : Specifies the version of the template that you want to delete. If you don't provide a version number, <code>DeleteTemplate</code> deletes all versions of the template. 
  var path_21626357 = newJObject()
  var query_21626358 = newJObject()
  add(path_21626357, "AwsAccountId", newJString(AwsAccountId))
  add(path_21626357, "TemplateId", newJString(TemplateId))
  add(query_21626358, "version-number", newJInt(versionNumber))
  result = call_21626356.call(path_21626357, query_21626358, nil, nil, nil)

var deleteTemplate* = Call_DeleteTemplate_21626342(name: "deleteTemplate",
    meth: HttpMethod.HttpDelete, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates/{TemplateId}",
    validator: validate_DeleteTemplate_21626343, base: "/",
    makeUrl: url_DeleteTemplate_21626344, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTemplateAlias_21626375 = ref object of OpenApiRestCall_21625435
proc url_UpdateTemplateAlias_21626377(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "TemplateId" in path, "`TemplateId` is a required path parameter"
  assert "AliasName" in path, "`AliasName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/templates/"),
               (kind: VariableSegment, value: "TemplateId"),
               (kind: ConstantSegment, value: "/aliases/"),
               (kind: VariableSegment, value: "AliasName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateTemplateAlias_21626376(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates the template alias of a template.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account that contains the template alias that you're updating.
  ##   TemplateId: JString (required)
  ##             : The ID for the template.
  ##   AliasName: JString (required)
  ##            : The alias of the template that you want to update. If you name a specific alias, you update the version that the alias points to. You can specify the latest version of the template by providing the keyword <code>$LATEST</code> in the <code>AliasName</code> parameter. The keyword <code>$PUBLISHED</code> doesn't apply to templates.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_21626378 = path.getOrDefault("AwsAccountId")
  valid_21626378 = validateParameter(valid_21626378, JString, required = true,
                                   default = nil)
  if valid_21626378 != nil:
    section.add "AwsAccountId", valid_21626378
  var valid_21626379 = path.getOrDefault("TemplateId")
  valid_21626379 = validateParameter(valid_21626379, JString, required = true,
                                   default = nil)
  if valid_21626379 != nil:
    section.add "TemplateId", valid_21626379
  var valid_21626380 = path.getOrDefault("AliasName")
  valid_21626380 = validateParameter(valid_21626380, JString, required = true,
                                   default = nil)
  if valid_21626380 != nil:
    section.add "AliasName", valid_21626380
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626381 = header.getOrDefault("X-Amz-Date")
  valid_21626381 = validateParameter(valid_21626381, JString, required = false,
                                   default = nil)
  if valid_21626381 != nil:
    section.add "X-Amz-Date", valid_21626381
  var valid_21626382 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626382 = validateParameter(valid_21626382, JString, required = false,
                                   default = nil)
  if valid_21626382 != nil:
    section.add "X-Amz-Security-Token", valid_21626382
  var valid_21626383 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626383 = validateParameter(valid_21626383, JString, required = false,
                                   default = nil)
  if valid_21626383 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626383
  var valid_21626384 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626384 = validateParameter(valid_21626384, JString, required = false,
                                   default = nil)
  if valid_21626384 != nil:
    section.add "X-Amz-Algorithm", valid_21626384
  var valid_21626385 = header.getOrDefault("X-Amz-Signature")
  valid_21626385 = validateParameter(valid_21626385, JString, required = false,
                                   default = nil)
  if valid_21626385 != nil:
    section.add "X-Amz-Signature", valid_21626385
  var valid_21626386 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626386 = validateParameter(valid_21626386, JString, required = false,
                                   default = nil)
  if valid_21626386 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626386
  var valid_21626387 = header.getOrDefault("X-Amz-Credential")
  valid_21626387 = validateParameter(valid_21626387, JString, required = false,
                                   default = nil)
  if valid_21626387 != nil:
    section.add "X-Amz-Credential", valid_21626387
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626389: Call_UpdateTemplateAlias_21626375; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the template alias of a template.
  ## 
  let valid = call_21626389.validator(path, query, header, formData, body, _)
  let scheme = call_21626389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626389.makeUrl(scheme.get, call_21626389.host, call_21626389.base,
                               call_21626389.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626389, uri, valid, _)

proc call*(call_21626390: Call_UpdateTemplateAlias_21626375; AwsAccountId: string;
          TemplateId: string; body: JsonNode; AliasName: string): Recallable =
  ## updateTemplateAlias
  ## Updates the template alias of a template.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the template alias that you're updating.
  ##   TemplateId: string (required)
  ##             : The ID for the template.
  ##   body: JObject (required)
  ##   AliasName: string (required)
  ##            : The alias of the template that you want to update. If you name a specific alias, you update the version that the alias points to. You can specify the latest version of the template by providing the keyword <code>$LATEST</code> in the <code>AliasName</code> parameter. The keyword <code>$PUBLISHED</code> doesn't apply to templates.
  var path_21626391 = newJObject()
  var body_21626392 = newJObject()
  add(path_21626391, "AwsAccountId", newJString(AwsAccountId))
  add(path_21626391, "TemplateId", newJString(TemplateId))
  if body != nil:
    body_21626392 = body
  add(path_21626391, "AliasName", newJString(AliasName))
  result = call_21626390.call(path_21626391, nil, nil, nil, body_21626392)

var updateTemplateAlias* = Call_UpdateTemplateAlias_21626375(
    name: "updateTemplateAlias", meth: HttpMethod.HttpPut,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/templates/{TemplateId}/aliases/{AliasName}",
    validator: validate_UpdateTemplateAlias_21626376, base: "/",
    makeUrl: url_UpdateTemplateAlias_21626377,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTemplateAlias_21626393 = ref object of OpenApiRestCall_21625435
proc url_CreateTemplateAlias_21626395(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "TemplateId" in path, "`TemplateId` is a required path parameter"
  assert "AliasName" in path, "`AliasName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/templates/"),
               (kind: VariableSegment, value: "TemplateId"),
               (kind: ConstantSegment, value: "/aliases/"),
               (kind: VariableSegment, value: "AliasName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateTemplateAlias_21626394(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a template alias for a template.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account that contains the template that you creating an alias for.
  ##   TemplateId: JString (required)
  ##             : An ID for the template.
  ##   AliasName: JString (required)
  ##            : The name that you want to give to the template alias that you're creating. Don't start the alias name with the <code>$</code> character. Alias names that start with <code>$</code> are reserved by QuickSight. 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_21626396 = path.getOrDefault("AwsAccountId")
  valid_21626396 = validateParameter(valid_21626396, JString, required = true,
                                   default = nil)
  if valid_21626396 != nil:
    section.add "AwsAccountId", valid_21626396
  var valid_21626397 = path.getOrDefault("TemplateId")
  valid_21626397 = validateParameter(valid_21626397, JString, required = true,
                                   default = nil)
  if valid_21626397 != nil:
    section.add "TemplateId", valid_21626397
  var valid_21626398 = path.getOrDefault("AliasName")
  valid_21626398 = validateParameter(valid_21626398, JString, required = true,
                                   default = nil)
  if valid_21626398 != nil:
    section.add "AliasName", valid_21626398
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626399 = header.getOrDefault("X-Amz-Date")
  valid_21626399 = validateParameter(valid_21626399, JString, required = false,
                                   default = nil)
  if valid_21626399 != nil:
    section.add "X-Amz-Date", valid_21626399
  var valid_21626400 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626400 = validateParameter(valid_21626400, JString, required = false,
                                   default = nil)
  if valid_21626400 != nil:
    section.add "X-Amz-Security-Token", valid_21626400
  var valid_21626401 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626401 = validateParameter(valid_21626401, JString, required = false,
                                   default = nil)
  if valid_21626401 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626401
  var valid_21626402 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626402 = validateParameter(valid_21626402, JString, required = false,
                                   default = nil)
  if valid_21626402 != nil:
    section.add "X-Amz-Algorithm", valid_21626402
  var valid_21626403 = header.getOrDefault("X-Amz-Signature")
  valid_21626403 = validateParameter(valid_21626403, JString, required = false,
                                   default = nil)
  if valid_21626403 != nil:
    section.add "X-Amz-Signature", valid_21626403
  var valid_21626404 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626404 = validateParameter(valid_21626404, JString, required = false,
                                   default = nil)
  if valid_21626404 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626404
  var valid_21626405 = header.getOrDefault("X-Amz-Credential")
  valid_21626405 = validateParameter(valid_21626405, JString, required = false,
                                   default = nil)
  if valid_21626405 != nil:
    section.add "X-Amz-Credential", valid_21626405
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626407: Call_CreateTemplateAlias_21626393; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a template alias for a template.
  ## 
  let valid = call_21626407.validator(path, query, header, formData, body, _)
  let scheme = call_21626407.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626407.makeUrl(scheme.get, call_21626407.host, call_21626407.base,
                               call_21626407.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626407, uri, valid, _)

proc call*(call_21626408: Call_CreateTemplateAlias_21626393; AwsAccountId: string;
          TemplateId: string; body: JsonNode; AliasName: string): Recallable =
  ## createTemplateAlias
  ## Creates a template alias for a template.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the template that you creating an alias for.
  ##   TemplateId: string (required)
  ##             : An ID for the template.
  ##   body: JObject (required)
  ##   AliasName: string (required)
  ##            : The name that you want to give to the template alias that you're creating. Don't start the alias name with the <code>$</code> character. Alias names that start with <code>$</code> are reserved by QuickSight. 
  var path_21626409 = newJObject()
  var body_21626410 = newJObject()
  add(path_21626409, "AwsAccountId", newJString(AwsAccountId))
  add(path_21626409, "TemplateId", newJString(TemplateId))
  if body != nil:
    body_21626410 = body
  add(path_21626409, "AliasName", newJString(AliasName))
  result = call_21626408.call(path_21626409, nil, nil, nil, body_21626410)

var createTemplateAlias* = Call_CreateTemplateAlias_21626393(
    name: "createTemplateAlias", meth: HttpMethod.HttpPost,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/templates/{TemplateId}/aliases/{AliasName}",
    validator: validate_CreateTemplateAlias_21626394, base: "/",
    makeUrl: url_CreateTemplateAlias_21626395,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTemplateAlias_21626359 = ref object of OpenApiRestCall_21625435
proc url_DescribeTemplateAlias_21626361(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "TemplateId" in path, "`TemplateId` is a required path parameter"
  assert "AliasName" in path, "`AliasName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/templates/"),
               (kind: VariableSegment, value: "TemplateId"),
               (kind: ConstantSegment, value: "/aliases/"),
               (kind: VariableSegment, value: "AliasName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeTemplateAlias_21626360(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Describes the template alias for a template.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account that contains the template alias that you're describing.
  ##   TemplateId: JString (required)
  ##             : The ID for the template.
  ##   AliasName: JString (required)
  ##            : The name of the template alias that you want to describe. If you name a specific alias, you describe the version that the alias points to. You can specify the latest version of the template by providing the keyword <code>$LATEST</code> in the <code>AliasName</code> parameter. The keyword <code>$PUBLISHED</code> doesn't apply to templates.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_21626362 = path.getOrDefault("AwsAccountId")
  valid_21626362 = validateParameter(valid_21626362, JString, required = true,
                                   default = nil)
  if valid_21626362 != nil:
    section.add "AwsAccountId", valid_21626362
  var valid_21626363 = path.getOrDefault("TemplateId")
  valid_21626363 = validateParameter(valid_21626363, JString, required = true,
                                   default = nil)
  if valid_21626363 != nil:
    section.add "TemplateId", valid_21626363
  var valid_21626364 = path.getOrDefault("AliasName")
  valid_21626364 = validateParameter(valid_21626364, JString, required = true,
                                   default = nil)
  if valid_21626364 != nil:
    section.add "AliasName", valid_21626364
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626365 = header.getOrDefault("X-Amz-Date")
  valid_21626365 = validateParameter(valid_21626365, JString, required = false,
                                   default = nil)
  if valid_21626365 != nil:
    section.add "X-Amz-Date", valid_21626365
  var valid_21626366 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626366 = validateParameter(valid_21626366, JString, required = false,
                                   default = nil)
  if valid_21626366 != nil:
    section.add "X-Amz-Security-Token", valid_21626366
  var valid_21626367 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626367 = validateParameter(valid_21626367, JString, required = false,
                                   default = nil)
  if valid_21626367 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626367
  var valid_21626368 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626368 = validateParameter(valid_21626368, JString, required = false,
                                   default = nil)
  if valid_21626368 != nil:
    section.add "X-Amz-Algorithm", valid_21626368
  var valid_21626369 = header.getOrDefault("X-Amz-Signature")
  valid_21626369 = validateParameter(valid_21626369, JString, required = false,
                                   default = nil)
  if valid_21626369 != nil:
    section.add "X-Amz-Signature", valid_21626369
  var valid_21626370 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626370 = validateParameter(valid_21626370, JString, required = false,
                                   default = nil)
  if valid_21626370 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626370
  var valid_21626371 = header.getOrDefault("X-Amz-Credential")
  valid_21626371 = validateParameter(valid_21626371, JString, required = false,
                                   default = nil)
  if valid_21626371 != nil:
    section.add "X-Amz-Credential", valid_21626371
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626372: Call_DescribeTemplateAlias_21626359;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the template alias for a template.
  ## 
  let valid = call_21626372.validator(path, query, header, formData, body, _)
  let scheme = call_21626372.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626372.makeUrl(scheme.get, call_21626372.host, call_21626372.base,
                               call_21626372.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626372, uri, valid, _)

proc call*(call_21626373: Call_DescribeTemplateAlias_21626359;
          AwsAccountId: string; TemplateId: string; AliasName: string): Recallable =
  ## describeTemplateAlias
  ## Describes the template alias for a template.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the template alias that you're describing.
  ##   TemplateId: string (required)
  ##             : The ID for the template.
  ##   AliasName: string (required)
  ##            : The name of the template alias that you want to describe. If you name a specific alias, you describe the version that the alias points to. You can specify the latest version of the template by providing the keyword <code>$LATEST</code> in the <code>AliasName</code> parameter. The keyword <code>$PUBLISHED</code> doesn't apply to templates.
  var path_21626374 = newJObject()
  add(path_21626374, "AwsAccountId", newJString(AwsAccountId))
  add(path_21626374, "TemplateId", newJString(TemplateId))
  add(path_21626374, "AliasName", newJString(AliasName))
  result = call_21626373.call(path_21626374, nil, nil, nil, nil)

var describeTemplateAlias* = Call_DescribeTemplateAlias_21626359(
    name: "describeTemplateAlias", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/templates/{TemplateId}/aliases/{AliasName}",
    validator: validate_DescribeTemplateAlias_21626360, base: "/",
    makeUrl: url_DescribeTemplateAlias_21626361,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTemplateAlias_21626411 = ref object of OpenApiRestCall_21625435
proc url_DeleteTemplateAlias_21626413(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "TemplateId" in path, "`TemplateId` is a required path parameter"
  assert "AliasName" in path, "`AliasName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/templates/"),
               (kind: VariableSegment, value: "TemplateId"),
               (kind: ConstantSegment, value: "/aliases/"),
               (kind: VariableSegment, value: "AliasName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteTemplateAlias_21626412(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes the item that the specified template alias points to. If you provide a specific alias, you delete the version of the template that the alias points to.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account that contains the item to delete.
  ##   TemplateId: JString (required)
  ##             : The ID for the template that the specified alias is for.
  ##   AliasName: JString (required)
  ##            : The name for the template alias. If you name a specific alias, you delete the version that the alias points to. You can specify the latest version of the template by providing the keyword <code>$LATEST</code> in the <code>AliasName</code> parameter. 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_21626414 = path.getOrDefault("AwsAccountId")
  valid_21626414 = validateParameter(valid_21626414, JString, required = true,
                                   default = nil)
  if valid_21626414 != nil:
    section.add "AwsAccountId", valid_21626414
  var valid_21626415 = path.getOrDefault("TemplateId")
  valid_21626415 = validateParameter(valid_21626415, JString, required = true,
                                   default = nil)
  if valid_21626415 != nil:
    section.add "TemplateId", valid_21626415
  var valid_21626416 = path.getOrDefault("AliasName")
  valid_21626416 = validateParameter(valid_21626416, JString, required = true,
                                   default = nil)
  if valid_21626416 != nil:
    section.add "AliasName", valid_21626416
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626417 = header.getOrDefault("X-Amz-Date")
  valid_21626417 = validateParameter(valid_21626417, JString, required = false,
                                   default = nil)
  if valid_21626417 != nil:
    section.add "X-Amz-Date", valid_21626417
  var valid_21626418 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626418 = validateParameter(valid_21626418, JString, required = false,
                                   default = nil)
  if valid_21626418 != nil:
    section.add "X-Amz-Security-Token", valid_21626418
  var valid_21626419 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626419 = validateParameter(valid_21626419, JString, required = false,
                                   default = nil)
  if valid_21626419 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626419
  var valid_21626420 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626420 = validateParameter(valid_21626420, JString, required = false,
                                   default = nil)
  if valid_21626420 != nil:
    section.add "X-Amz-Algorithm", valid_21626420
  var valid_21626421 = header.getOrDefault("X-Amz-Signature")
  valid_21626421 = validateParameter(valid_21626421, JString, required = false,
                                   default = nil)
  if valid_21626421 != nil:
    section.add "X-Amz-Signature", valid_21626421
  var valid_21626422 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626422 = validateParameter(valid_21626422, JString, required = false,
                                   default = nil)
  if valid_21626422 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626422
  var valid_21626423 = header.getOrDefault("X-Amz-Credential")
  valid_21626423 = validateParameter(valid_21626423, JString, required = false,
                                   default = nil)
  if valid_21626423 != nil:
    section.add "X-Amz-Credential", valid_21626423
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626424: Call_DeleteTemplateAlias_21626411; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the item that the specified template alias points to. If you provide a specific alias, you delete the version of the template that the alias points to.
  ## 
  let valid = call_21626424.validator(path, query, header, formData, body, _)
  let scheme = call_21626424.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626424.makeUrl(scheme.get, call_21626424.host, call_21626424.base,
                               call_21626424.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626424, uri, valid, _)

proc call*(call_21626425: Call_DeleteTemplateAlias_21626411; AwsAccountId: string;
          TemplateId: string; AliasName: string): Recallable =
  ## deleteTemplateAlias
  ## Deletes the item that the specified template alias points to. If you provide a specific alias, you delete the version of the template that the alias points to.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the item to delete.
  ##   TemplateId: string (required)
  ##             : The ID for the template that the specified alias is for.
  ##   AliasName: string (required)
  ##            : The name for the template alias. If you name a specific alias, you delete the version that the alias points to. You can specify the latest version of the template by providing the keyword <code>$LATEST</code> in the <code>AliasName</code> parameter. 
  var path_21626426 = newJObject()
  add(path_21626426, "AwsAccountId", newJString(AwsAccountId))
  add(path_21626426, "TemplateId", newJString(TemplateId))
  add(path_21626426, "AliasName", newJString(AliasName))
  result = call_21626425.call(path_21626426, nil, nil, nil, nil)

var deleteTemplateAlias* = Call_DeleteTemplateAlias_21626411(
    name: "deleteTemplateAlias", meth: HttpMethod.HttpDelete,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/templates/{TemplateId}/aliases/{AliasName}",
    validator: validate_DeleteTemplateAlias_21626412, base: "/",
    makeUrl: url_DeleteTemplateAlias_21626413,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDataSet_21626442 = ref object of OpenApiRestCall_21625435
proc url_UpdateDataSet_21626444(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/data-sets/"),
               (kind: VariableSegment, value: "DataSetId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDataSet_21626443(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Updates a dataset.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID.
  ##   DataSetId: JString (required)
  ##            : The ID for the dataset that you want to update. This ID is unique per AWS Region for each AWS account.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_21626445 = path.getOrDefault("AwsAccountId")
  valid_21626445 = validateParameter(valid_21626445, JString, required = true,
                                   default = nil)
  if valid_21626445 != nil:
    section.add "AwsAccountId", valid_21626445
  var valid_21626446 = path.getOrDefault("DataSetId")
  valid_21626446 = validateParameter(valid_21626446, JString, required = true,
                                   default = nil)
  if valid_21626446 != nil:
    section.add "DataSetId", valid_21626446
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626447 = header.getOrDefault("X-Amz-Date")
  valid_21626447 = validateParameter(valid_21626447, JString, required = false,
                                   default = nil)
  if valid_21626447 != nil:
    section.add "X-Amz-Date", valid_21626447
  var valid_21626448 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626448 = validateParameter(valid_21626448, JString, required = false,
                                   default = nil)
  if valid_21626448 != nil:
    section.add "X-Amz-Security-Token", valid_21626448
  var valid_21626449 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626449 = validateParameter(valid_21626449, JString, required = false,
                                   default = nil)
  if valid_21626449 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626449
  var valid_21626450 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626450 = validateParameter(valid_21626450, JString, required = false,
                                   default = nil)
  if valid_21626450 != nil:
    section.add "X-Amz-Algorithm", valid_21626450
  var valid_21626451 = header.getOrDefault("X-Amz-Signature")
  valid_21626451 = validateParameter(valid_21626451, JString, required = false,
                                   default = nil)
  if valid_21626451 != nil:
    section.add "X-Amz-Signature", valid_21626451
  var valid_21626452 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626452 = validateParameter(valid_21626452, JString, required = false,
                                   default = nil)
  if valid_21626452 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626452
  var valid_21626453 = header.getOrDefault("X-Amz-Credential")
  valid_21626453 = validateParameter(valid_21626453, JString, required = false,
                                   default = nil)
  if valid_21626453 != nil:
    section.add "X-Amz-Credential", valid_21626453
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626455: Call_UpdateDataSet_21626442; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a dataset.
  ## 
  let valid = call_21626455.validator(path, query, header, formData, body, _)
  let scheme = call_21626455.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626455.makeUrl(scheme.get, call_21626455.host, call_21626455.base,
                               call_21626455.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626455, uri, valid, _)

proc call*(call_21626456: Call_UpdateDataSet_21626442; AwsAccountId: string;
          body: JsonNode; DataSetId: string): Recallable =
  ## updateDataSet
  ## Updates a dataset.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   body: JObject (required)
  ##   DataSetId: string (required)
  ##            : The ID for the dataset that you want to update. This ID is unique per AWS Region for each AWS account.
  var path_21626457 = newJObject()
  var body_21626458 = newJObject()
  add(path_21626457, "AwsAccountId", newJString(AwsAccountId))
  if body != nil:
    body_21626458 = body
  add(path_21626457, "DataSetId", newJString(DataSetId))
  result = call_21626456.call(path_21626457, nil, nil, nil, body_21626458)

var updateDataSet* = Call_UpdateDataSet_21626442(name: "updateDataSet",
    meth: HttpMethod.HttpPut, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}",
    validator: validate_UpdateDataSet_21626443, base: "/",
    makeUrl: url_UpdateDataSet_21626444, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDataSet_21626427 = ref object of OpenApiRestCall_21625435
proc url_DescribeDataSet_21626429(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/data-sets/"),
               (kind: VariableSegment, value: "DataSetId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeDataSet_21626428(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Describes a dataset. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID.
  ##   DataSetId: JString (required)
  ##            : The ID for the dataset that you want to create. This ID is unique per AWS Region for each AWS account.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_21626430 = path.getOrDefault("AwsAccountId")
  valid_21626430 = validateParameter(valid_21626430, JString, required = true,
                                   default = nil)
  if valid_21626430 != nil:
    section.add "AwsAccountId", valid_21626430
  var valid_21626431 = path.getOrDefault("DataSetId")
  valid_21626431 = validateParameter(valid_21626431, JString, required = true,
                                   default = nil)
  if valid_21626431 != nil:
    section.add "DataSetId", valid_21626431
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626432 = header.getOrDefault("X-Amz-Date")
  valid_21626432 = validateParameter(valid_21626432, JString, required = false,
                                   default = nil)
  if valid_21626432 != nil:
    section.add "X-Amz-Date", valid_21626432
  var valid_21626433 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626433 = validateParameter(valid_21626433, JString, required = false,
                                   default = nil)
  if valid_21626433 != nil:
    section.add "X-Amz-Security-Token", valid_21626433
  var valid_21626434 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626434 = validateParameter(valid_21626434, JString, required = false,
                                   default = nil)
  if valid_21626434 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626434
  var valid_21626435 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626435 = validateParameter(valid_21626435, JString, required = false,
                                   default = nil)
  if valid_21626435 != nil:
    section.add "X-Amz-Algorithm", valid_21626435
  var valid_21626436 = header.getOrDefault("X-Amz-Signature")
  valid_21626436 = validateParameter(valid_21626436, JString, required = false,
                                   default = nil)
  if valid_21626436 != nil:
    section.add "X-Amz-Signature", valid_21626436
  var valid_21626437 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626437 = validateParameter(valid_21626437, JString, required = false,
                                   default = nil)
  if valid_21626437 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626437
  var valid_21626438 = header.getOrDefault("X-Amz-Credential")
  valid_21626438 = validateParameter(valid_21626438, JString, required = false,
                                   default = nil)
  if valid_21626438 != nil:
    section.add "X-Amz-Credential", valid_21626438
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626439: Call_DescribeDataSet_21626427; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes a dataset. 
  ## 
  let valid = call_21626439.validator(path, query, header, formData, body, _)
  let scheme = call_21626439.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626439.makeUrl(scheme.get, call_21626439.host, call_21626439.base,
                               call_21626439.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626439, uri, valid, _)

proc call*(call_21626440: Call_DescribeDataSet_21626427; AwsAccountId: string;
          DataSetId: string): Recallable =
  ## describeDataSet
  ## Describes a dataset. 
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSetId: string (required)
  ##            : The ID for the dataset that you want to create. This ID is unique per AWS Region for each AWS account.
  var path_21626441 = newJObject()
  add(path_21626441, "AwsAccountId", newJString(AwsAccountId))
  add(path_21626441, "DataSetId", newJString(DataSetId))
  result = call_21626440.call(path_21626441, nil, nil, nil, nil)

var describeDataSet* = Call_DescribeDataSet_21626427(name: "describeDataSet",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}",
    validator: validate_DescribeDataSet_21626428, base: "/",
    makeUrl: url_DescribeDataSet_21626429, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDataSet_21626459 = ref object of OpenApiRestCall_21625435
proc url_DeleteDataSet_21626461(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/data-sets/"),
               (kind: VariableSegment, value: "DataSetId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDataSet_21626460(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Deletes a dataset.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID.
  ##   DataSetId: JString (required)
  ##            : The ID for the dataset that you want to create. This ID is unique per AWS Region for each AWS account.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_21626462 = path.getOrDefault("AwsAccountId")
  valid_21626462 = validateParameter(valid_21626462, JString, required = true,
                                   default = nil)
  if valid_21626462 != nil:
    section.add "AwsAccountId", valid_21626462
  var valid_21626463 = path.getOrDefault("DataSetId")
  valid_21626463 = validateParameter(valid_21626463, JString, required = true,
                                   default = nil)
  if valid_21626463 != nil:
    section.add "DataSetId", valid_21626463
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626464 = header.getOrDefault("X-Amz-Date")
  valid_21626464 = validateParameter(valid_21626464, JString, required = false,
                                   default = nil)
  if valid_21626464 != nil:
    section.add "X-Amz-Date", valid_21626464
  var valid_21626465 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626465 = validateParameter(valid_21626465, JString, required = false,
                                   default = nil)
  if valid_21626465 != nil:
    section.add "X-Amz-Security-Token", valid_21626465
  var valid_21626466 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626466 = validateParameter(valid_21626466, JString, required = false,
                                   default = nil)
  if valid_21626466 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626466
  var valid_21626467 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626467 = validateParameter(valid_21626467, JString, required = false,
                                   default = nil)
  if valid_21626467 != nil:
    section.add "X-Amz-Algorithm", valid_21626467
  var valid_21626468 = header.getOrDefault("X-Amz-Signature")
  valid_21626468 = validateParameter(valid_21626468, JString, required = false,
                                   default = nil)
  if valid_21626468 != nil:
    section.add "X-Amz-Signature", valid_21626468
  var valid_21626469 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626469 = validateParameter(valid_21626469, JString, required = false,
                                   default = nil)
  if valid_21626469 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626469
  var valid_21626470 = header.getOrDefault("X-Amz-Credential")
  valid_21626470 = validateParameter(valid_21626470, JString, required = false,
                                   default = nil)
  if valid_21626470 != nil:
    section.add "X-Amz-Credential", valid_21626470
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626471: Call_DeleteDataSet_21626459; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a dataset.
  ## 
  let valid = call_21626471.validator(path, query, header, formData, body, _)
  let scheme = call_21626471.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626471.makeUrl(scheme.get, call_21626471.host, call_21626471.base,
                               call_21626471.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626471, uri, valid, _)

proc call*(call_21626472: Call_DeleteDataSet_21626459; AwsAccountId: string;
          DataSetId: string): Recallable =
  ## deleteDataSet
  ## Deletes a dataset.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSetId: string (required)
  ##            : The ID for the dataset that you want to create. This ID is unique per AWS Region for each AWS account.
  var path_21626473 = newJObject()
  add(path_21626473, "AwsAccountId", newJString(AwsAccountId))
  add(path_21626473, "DataSetId", newJString(DataSetId))
  result = call_21626472.call(path_21626473, nil, nil, nil, nil)

var deleteDataSet* = Call_DeleteDataSet_21626459(name: "deleteDataSet",
    meth: HttpMethod.HttpDelete, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}",
    validator: validate_DeleteDataSet_21626460, base: "/",
    makeUrl: url_DeleteDataSet_21626461, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDataSource_21626489 = ref object of OpenApiRestCall_21625435
proc url_UpdateDataSource_21626491(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "DataSourceId" in path, "`DataSourceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/data-sources/"),
               (kind: VariableSegment, value: "DataSourceId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDataSource_21626490(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates a data source.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID.
  ##   DataSourceId: JString (required)
  ##               : The ID of the data source. This ID is unique per AWS Region for each AWS account. 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_21626492 = path.getOrDefault("AwsAccountId")
  valid_21626492 = validateParameter(valid_21626492, JString, required = true,
                                   default = nil)
  if valid_21626492 != nil:
    section.add "AwsAccountId", valid_21626492
  var valid_21626493 = path.getOrDefault("DataSourceId")
  valid_21626493 = validateParameter(valid_21626493, JString, required = true,
                                   default = nil)
  if valid_21626493 != nil:
    section.add "DataSourceId", valid_21626493
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626494 = header.getOrDefault("X-Amz-Date")
  valid_21626494 = validateParameter(valid_21626494, JString, required = false,
                                   default = nil)
  if valid_21626494 != nil:
    section.add "X-Amz-Date", valid_21626494
  var valid_21626495 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626495 = validateParameter(valid_21626495, JString, required = false,
                                   default = nil)
  if valid_21626495 != nil:
    section.add "X-Amz-Security-Token", valid_21626495
  var valid_21626496 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626496 = validateParameter(valid_21626496, JString, required = false,
                                   default = nil)
  if valid_21626496 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626496
  var valid_21626497 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626497 = validateParameter(valid_21626497, JString, required = false,
                                   default = nil)
  if valid_21626497 != nil:
    section.add "X-Amz-Algorithm", valid_21626497
  var valid_21626498 = header.getOrDefault("X-Amz-Signature")
  valid_21626498 = validateParameter(valid_21626498, JString, required = false,
                                   default = nil)
  if valid_21626498 != nil:
    section.add "X-Amz-Signature", valid_21626498
  var valid_21626499 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626499 = validateParameter(valid_21626499, JString, required = false,
                                   default = nil)
  if valid_21626499 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626499
  var valid_21626500 = header.getOrDefault("X-Amz-Credential")
  valid_21626500 = validateParameter(valid_21626500, JString, required = false,
                                   default = nil)
  if valid_21626500 != nil:
    section.add "X-Amz-Credential", valid_21626500
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626502: Call_UpdateDataSource_21626489; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a data source.
  ## 
  let valid = call_21626502.validator(path, query, header, formData, body, _)
  let scheme = call_21626502.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626502.makeUrl(scheme.get, call_21626502.host, call_21626502.base,
                               call_21626502.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626502, uri, valid, _)

proc call*(call_21626503: Call_UpdateDataSource_21626489; AwsAccountId: string;
          DataSourceId: string; body: JsonNode): Recallable =
  ## updateDataSource
  ## Updates a data source.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSourceId: string (required)
  ##               : The ID of the data source. This ID is unique per AWS Region for each AWS account. 
  ##   body: JObject (required)
  var path_21626504 = newJObject()
  var body_21626505 = newJObject()
  add(path_21626504, "AwsAccountId", newJString(AwsAccountId))
  add(path_21626504, "DataSourceId", newJString(DataSourceId))
  if body != nil:
    body_21626505 = body
  result = call_21626503.call(path_21626504, nil, nil, nil, body_21626505)

var updateDataSource* = Call_UpdateDataSource_21626489(name: "updateDataSource",
    meth: HttpMethod.HttpPut, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sources/{DataSourceId}",
    validator: validate_UpdateDataSource_21626490, base: "/",
    makeUrl: url_UpdateDataSource_21626491, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDataSource_21626474 = ref object of OpenApiRestCall_21625435
proc url_DescribeDataSource_21626476(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "DataSourceId" in path, "`DataSourceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/data-sources/"),
               (kind: VariableSegment, value: "DataSourceId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeDataSource_21626475(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Describes a data source.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID.
  ##   DataSourceId: JString (required)
  ##               : The ID of the data source. This ID is unique per AWS Region for each AWS account.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_21626477 = path.getOrDefault("AwsAccountId")
  valid_21626477 = validateParameter(valid_21626477, JString, required = true,
                                   default = nil)
  if valid_21626477 != nil:
    section.add "AwsAccountId", valid_21626477
  var valid_21626478 = path.getOrDefault("DataSourceId")
  valid_21626478 = validateParameter(valid_21626478, JString, required = true,
                                   default = nil)
  if valid_21626478 != nil:
    section.add "DataSourceId", valid_21626478
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626479 = header.getOrDefault("X-Amz-Date")
  valid_21626479 = validateParameter(valid_21626479, JString, required = false,
                                   default = nil)
  if valid_21626479 != nil:
    section.add "X-Amz-Date", valid_21626479
  var valid_21626480 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626480 = validateParameter(valid_21626480, JString, required = false,
                                   default = nil)
  if valid_21626480 != nil:
    section.add "X-Amz-Security-Token", valid_21626480
  var valid_21626481 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626481 = validateParameter(valid_21626481, JString, required = false,
                                   default = nil)
  if valid_21626481 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626481
  var valid_21626482 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626482 = validateParameter(valid_21626482, JString, required = false,
                                   default = nil)
  if valid_21626482 != nil:
    section.add "X-Amz-Algorithm", valid_21626482
  var valid_21626483 = header.getOrDefault("X-Amz-Signature")
  valid_21626483 = validateParameter(valid_21626483, JString, required = false,
                                   default = nil)
  if valid_21626483 != nil:
    section.add "X-Amz-Signature", valid_21626483
  var valid_21626484 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626484 = validateParameter(valid_21626484, JString, required = false,
                                   default = nil)
  if valid_21626484 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626484
  var valid_21626485 = header.getOrDefault("X-Amz-Credential")
  valid_21626485 = validateParameter(valid_21626485, JString, required = false,
                                   default = nil)
  if valid_21626485 != nil:
    section.add "X-Amz-Credential", valid_21626485
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626486: Call_DescribeDataSource_21626474; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes a data source.
  ## 
  let valid = call_21626486.validator(path, query, header, formData, body, _)
  let scheme = call_21626486.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626486.makeUrl(scheme.get, call_21626486.host, call_21626486.base,
                               call_21626486.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626486, uri, valid, _)

proc call*(call_21626487: Call_DescribeDataSource_21626474; AwsAccountId: string;
          DataSourceId: string): Recallable =
  ## describeDataSource
  ## Describes a data source.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSourceId: string (required)
  ##               : The ID of the data source. This ID is unique per AWS Region for each AWS account.
  var path_21626488 = newJObject()
  add(path_21626488, "AwsAccountId", newJString(AwsAccountId))
  add(path_21626488, "DataSourceId", newJString(DataSourceId))
  result = call_21626487.call(path_21626488, nil, nil, nil, nil)

var describeDataSource* = Call_DescribeDataSource_21626474(
    name: "describeDataSource", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sources/{DataSourceId}",
    validator: validate_DescribeDataSource_21626475, base: "/",
    makeUrl: url_DescribeDataSource_21626476, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDataSource_21626506 = ref object of OpenApiRestCall_21625435
proc url_DeleteDataSource_21626508(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "DataSourceId" in path, "`DataSourceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/data-sources/"),
               (kind: VariableSegment, value: "DataSourceId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDataSource_21626507(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes the data source permanently. This action breaks all the datasets that reference the deleted data source.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID.
  ##   DataSourceId: JString (required)
  ##               : The ID of the data source. This ID is unique per AWS Region for each AWS account.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_21626509 = path.getOrDefault("AwsAccountId")
  valid_21626509 = validateParameter(valid_21626509, JString, required = true,
                                   default = nil)
  if valid_21626509 != nil:
    section.add "AwsAccountId", valid_21626509
  var valid_21626510 = path.getOrDefault("DataSourceId")
  valid_21626510 = validateParameter(valid_21626510, JString, required = true,
                                   default = nil)
  if valid_21626510 != nil:
    section.add "DataSourceId", valid_21626510
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626511 = header.getOrDefault("X-Amz-Date")
  valid_21626511 = validateParameter(valid_21626511, JString, required = false,
                                   default = nil)
  if valid_21626511 != nil:
    section.add "X-Amz-Date", valid_21626511
  var valid_21626512 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626512 = validateParameter(valid_21626512, JString, required = false,
                                   default = nil)
  if valid_21626512 != nil:
    section.add "X-Amz-Security-Token", valid_21626512
  var valid_21626513 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626513 = validateParameter(valid_21626513, JString, required = false,
                                   default = nil)
  if valid_21626513 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626513
  var valid_21626514 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626514 = validateParameter(valid_21626514, JString, required = false,
                                   default = nil)
  if valid_21626514 != nil:
    section.add "X-Amz-Algorithm", valid_21626514
  var valid_21626515 = header.getOrDefault("X-Amz-Signature")
  valid_21626515 = validateParameter(valid_21626515, JString, required = false,
                                   default = nil)
  if valid_21626515 != nil:
    section.add "X-Amz-Signature", valid_21626515
  var valid_21626516 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626516 = validateParameter(valid_21626516, JString, required = false,
                                   default = nil)
  if valid_21626516 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626516
  var valid_21626517 = header.getOrDefault("X-Amz-Credential")
  valid_21626517 = validateParameter(valid_21626517, JString, required = false,
                                   default = nil)
  if valid_21626517 != nil:
    section.add "X-Amz-Credential", valid_21626517
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626518: Call_DeleteDataSource_21626506; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the data source permanently. This action breaks all the datasets that reference the deleted data source.
  ## 
  let valid = call_21626518.validator(path, query, header, formData, body, _)
  let scheme = call_21626518.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626518.makeUrl(scheme.get, call_21626518.host, call_21626518.base,
                               call_21626518.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626518, uri, valid, _)

proc call*(call_21626519: Call_DeleteDataSource_21626506; AwsAccountId: string;
          DataSourceId: string): Recallable =
  ## deleteDataSource
  ## Deletes the data source permanently. This action breaks all the datasets that reference the deleted data source.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSourceId: string (required)
  ##               : The ID of the data source. This ID is unique per AWS Region for each AWS account.
  var path_21626520 = newJObject()
  add(path_21626520, "AwsAccountId", newJString(AwsAccountId))
  add(path_21626520, "DataSourceId", newJString(DataSourceId))
  result = call_21626519.call(path_21626520, nil, nil, nil, nil)

var deleteDataSource* = Call_DeleteDataSource_21626506(name: "deleteDataSource",
    meth: HttpMethod.HttpDelete, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sources/{DataSourceId}",
    validator: validate_DeleteDataSource_21626507, base: "/",
    makeUrl: url_DeleteDataSource_21626508, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGroup_21626537 = ref object of OpenApiRestCall_21625435
proc url_UpdateGroup_21626539(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "Namespace" in path, "`Namespace` is a required path parameter"
  assert "GroupName" in path, "`GroupName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/namespaces/"),
               (kind: VariableSegment, value: "Namespace"),
               (kind: ConstantSegment, value: "/groups/"),
               (kind: VariableSegment, value: "GroupName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateGroup_21626538(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Changes a group description. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupName: JString (required)
  ##            : The name of the group that you want to update.
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupName` field"
  var valid_21626540 = path.getOrDefault("GroupName")
  valid_21626540 = validateParameter(valid_21626540, JString, required = true,
                                   default = nil)
  if valid_21626540 != nil:
    section.add "GroupName", valid_21626540
  var valid_21626541 = path.getOrDefault("AwsAccountId")
  valid_21626541 = validateParameter(valid_21626541, JString, required = true,
                                   default = nil)
  if valid_21626541 != nil:
    section.add "AwsAccountId", valid_21626541
  var valid_21626542 = path.getOrDefault("Namespace")
  valid_21626542 = validateParameter(valid_21626542, JString, required = true,
                                   default = nil)
  if valid_21626542 != nil:
    section.add "Namespace", valid_21626542
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626543 = header.getOrDefault("X-Amz-Date")
  valid_21626543 = validateParameter(valid_21626543, JString, required = false,
                                   default = nil)
  if valid_21626543 != nil:
    section.add "X-Amz-Date", valid_21626543
  var valid_21626544 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626544 = validateParameter(valid_21626544, JString, required = false,
                                   default = nil)
  if valid_21626544 != nil:
    section.add "X-Amz-Security-Token", valid_21626544
  var valid_21626545 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626545 = validateParameter(valid_21626545, JString, required = false,
                                   default = nil)
  if valid_21626545 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626545
  var valid_21626546 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626546 = validateParameter(valid_21626546, JString, required = false,
                                   default = nil)
  if valid_21626546 != nil:
    section.add "X-Amz-Algorithm", valid_21626546
  var valid_21626547 = header.getOrDefault("X-Amz-Signature")
  valid_21626547 = validateParameter(valid_21626547, JString, required = false,
                                   default = nil)
  if valid_21626547 != nil:
    section.add "X-Amz-Signature", valid_21626547
  var valid_21626548 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626548 = validateParameter(valid_21626548, JString, required = false,
                                   default = nil)
  if valid_21626548 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626548
  var valid_21626549 = header.getOrDefault("X-Amz-Credential")
  valid_21626549 = validateParameter(valid_21626549, JString, required = false,
                                   default = nil)
  if valid_21626549 != nil:
    section.add "X-Amz-Credential", valid_21626549
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626551: Call_UpdateGroup_21626537; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Changes a group description. 
  ## 
  let valid = call_21626551.validator(path, query, header, formData, body, _)
  let scheme = call_21626551.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626551.makeUrl(scheme.get, call_21626551.host, call_21626551.base,
                               call_21626551.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626551, uri, valid, _)

proc call*(call_21626552: Call_UpdateGroup_21626537; GroupName: string;
          AwsAccountId: string; body: JsonNode; Namespace: string): Recallable =
  ## updateGroup
  ## Changes a group description. 
  ##   GroupName: string (required)
  ##            : The name of the group that you want to update.
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   body: JObject (required)
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  var path_21626553 = newJObject()
  var body_21626554 = newJObject()
  add(path_21626553, "GroupName", newJString(GroupName))
  add(path_21626553, "AwsAccountId", newJString(AwsAccountId))
  if body != nil:
    body_21626554 = body
  add(path_21626553, "Namespace", newJString(Namespace))
  result = call_21626552.call(path_21626553, nil, nil, nil, body_21626554)

var updateGroup* = Call_UpdateGroup_21626537(name: "updateGroup",
    meth: HttpMethod.HttpPut, host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}",
    validator: validate_UpdateGroup_21626538, base: "/", makeUrl: url_UpdateGroup_21626539,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeGroup_21626521 = ref object of OpenApiRestCall_21625435
proc url_DescribeGroup_21626523(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "Namespace" in path, "`Namespace` is a required path parameter"
  assert "GroupName" in path, "`GroupName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/namespaces/"),
               (kind: VariableSegment, value: "Namespace"),
               (kind: ConstantSegment, value: "/groups/"),
               (kind: VariableSegment, value: "GroupName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeGroup_21626522(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Returns an Amazon QuickSight group's description and Amazon Resource Name (ARN). 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupName: JString (required)
  ##            : The name of the group that you want to describe.
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupName` field"
  var valid_21626524 = path.getOrDefault("GroupName")
  valid_21626524 = validateParameter(valid_21626524, JString, required = true,
                                   default = nil)
  if valid_21626524 != nil:
    section.add "GroupName", valid_21626524
  var valid_21626525 = path.getOrDefault("AwsAccountId")
  valid_21626525 = validateParameter(valid_21626525, JString, required = true,
                                   default = nil)
  if valid_21626525 != nil:
    section.add "AwsAccountId", valid_21626525
  var valid_21626526 = path.getOrDefault("Namespace")
  valid_21626526 = validateParameter(valid_21626526, JString, required = true,
                                   default = nil)
  if valid_21626526 != nil:
    section.add "Namespace", valid_21626526
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626527 = header.getOrDefault("X-Amz-Date")
  valid_21626527 = validateParameter(valid_21626527, JString, required = false,
                                   default = nil)
  if valid_21626527 != nil:
    section.add "X-Amz-Date", valid_21626527
  var valid_21626528 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626528 = validateParameter(valid_21626528, JString, required = false,
                                   default = nil)
  if valid_21626528 != nil:
    section.add "X-Amz-Security-Token", valid_21626528
  var valid_21626529 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626529 = validateParameter(valid_21626529, JString, required = false,
                                   default = nil)
  if valid_21626529 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626529
  var valid_21626530 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626530 = validateParameter(valid_21626530, JString, required = false,
                                   default = nil)
  if valid_21626530 != nil:
    section.add "X-Amz-Algorithm", valid_21626530
  var valid_21626531 = header.getOrDefault("X-Amz-Signature")
  valid_21626531 = validateParameter(valid_21626531, JString, required = false,
                                   default = nil)
  if valid_21626531 != nil:
    section.add "X-Amz-Signature", valid_21626531
  var valid_21626532 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626532 = validateParameter(valid_21626532, JString, required = false,
                                   default = nil)
  if valid_21626532 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626532
  var valid_21626533 = header.getOrDefault("X-Amz-Credential")
  valid_21626533 = validateParameter(valid_21626533, JString, required = false,
                                   default = nil)
  if valid_21626533 != nil:
    section.add "X-Amz-Credential", valid_21626533
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626534: Call_DescribeGroup_21626521; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns an Amazon QuickSight group's description and Amazon Resource Name (ARN). 
  ## 
  let valid = call_21626534.validator(path, query, header, formData, body, _)
  let scheme = call_21626534.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626534.makeUrl(scheme.get, call_21626534.host, call_21626534.base,
                               call_21626534.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626534, uri, valid, _)

proc call*(call_21626535: Call_DescribeGroup_21626521; GroupName: string;
          AwsAccountId: string; Namespace: string): Recallable =
  ## describeGroup
  ## Returns an Amazon QuickSight group's description and Amazon Resource Name (ARN). 
  ##   GroupName: string (required)
  ##            : The name of the group that you want to describe.
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  var path_21626536 = newJObject()
  add(path_21626536, "GroupName", newJString(GroupName))
  add(path_21626536, "AwsAccountId", newJString(AwsAccountId))
  add(path_21626536, "Namespace", newJString(Namespace))
  result = call_21626535.call(path_21626536, nil, nil, nil, nil)

var describeGroup* = Call_DescribeGroup_21626521(name: "describeGroup",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}",
    validator: validate_DescribeGroup_21626522, base: "/",
    makeUrl: url_DescribeGroup_21626523, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGroup_21626555 = ref object of OpenApiRestCall_21625435
proc url_DeleteGroup_21626557(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "Namespace" in path, "`Namespace` is a required path parameter"
  assert "GroupName" in path, "`GroupName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/namespaces/"),
               (kind: VariableSegment, value: "Namespace"),
               (kind: ConstantSegment, value: "/groups/"),
               (kind: VariableSegment, value: "GroupName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteGroup_21626556(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Removes a user group from Amazon QuickSight. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupName: JString (required)
  ##            : The name of the group that you want to delete.
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupName` field"
  var valid_21626558 = path.getOrDefault("GroupName")
  valid_21626558 = validateParameter(valid_21626558, JString, required = true,
                                   default = nil)
  if valid_21626558 != nil:
    section.add "GroupName", valid_21626558
  var valid_21626559 = path.getOrDefault("AwsAccountId")
  valid_21626559 = validateParameter(valid_21626559, JString, required = true,
                                   default = nil)
  if valid_21626559 != nil:
    section.add "AwsAccountId", valid_21626559
  var valid_21626560 = path.getOrDefault("Namespace")
  valid_21626560 = validateParameter(valid_21626560, JString, required = true,
                                   default = nil)
  if valid_21626560 != nil:
    section.add "Namespace", valid_21626560
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626561 = header.getOrDefault("X-Amz-Date")
  valid_21626561 = validateParameter(valid_21626561, JString, required = false,
                                   default = nil)
  if valid_21626561 != nil:
    section.add "X-Amz-Date", valid_21626561
  var valid_21626562 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626562 = validateParameter(valid_21626562, JString, required = false,
                                   default = nil)
  if valid_21626562 != nil:
    section.add "X-Amz-Security-Token", valid_21626562
  var valid_21626563 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626563 = validateParameter(valid_21626563, JString, required = false,
                                   default = nil)
  if valid_21626563 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626563
  var valid_21626564 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626564 = validateParameter(valid_21626564, JString, required = false,
                                   default = nil)
  if valid_21626564 != nil:
    section.add "X-Amz-Algorithm", valid_21626564
  var valid_21626565 = header.getOrDefault("X-Amz-Signature")
  valid_21626565 = validateParameter(valid_21626565, JString, required = false,
                                   default = nil)
  if valid_21626565 != nil:
    section.add "X-Amz-Signature", valid_21626565
  var valid_21626566 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626566 = validateParameter(valid_21626566, JString, required = false,
                                   default = nil)
  if valid_21626566 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626566
  var valid_21626567 = header.getOrDefault("X-Amz-Credential")
  valid_21626567 = validateParameter(valid_21626567, JString, required = false,
                                   default = nil)
  if valid_21626567 != nil:
    section.add "X-Amz-Credential", valid_21626567
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626568: Call_DeleteGroup_21626555; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes a user group from Amazon QuickSight. 
  ## 
  let valid = call_21626568.validator(path, query, header, formData, body, _)
  let scheme = call_21626568.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626568.makeUrl(scheme.get, call_21626568.host, call_21626568.base,
                               call_21626568.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626568, uri, valid, _)

proc call*(call_21626569: Call_DeleteGroup_21626555; GroupName: string;
          AwsAccountId: string; Namespace: string): Recallable =
  ## deleteGroup
  ## Removes a user group from Amazon QuickSight. 
  ##   GroupName: string (required)
  ##            : The name of the group that you want to delete.
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  var path_21626570 = newJObject()
  add(path_21626570, "GroupName", newJString(GroupName))
  add(path_21626570, "AwsAccountId", newJString(AwsAccountId))
  add(path_21626570, "Namespace", newJString(Namespace))
  result = call_21626569.call(path_21626570, nil, nil, nil, nil)

var deleteGroup* = Call_DeleteGroup_21626555(name: "deleteGroup",
    meth: HttpMethod.HttpDelete, host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}",
    validator: validate_DeleteGroup_21626556, base: "/", makeUrl: url_DeleteGroup_21626557,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIAMPolicyAssignment_21626571 = ref object of OpenApiRestCall_21625435
proc url_DeleteIAMPolicyAssignment_21626573(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "Namespace" in path, "`Namespace` is a required path parameter"
  assert "AssignmentName" in path, "`AssignmentName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/namespace/"),
               (kind: VariableSegment, value: "Namespace"),
               (kind: ConstantSegment, value: "/iam-policy-assignments/"),
               (kind: VariableSegment, value: "AssignmentName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteIAMPolicyAssignment_21626572(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes an existing IAM policy assignment.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AssignmentName: JString (required)
  ##                 : The name of the assignment. 
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID where you want to delete the IAM policy assignment.
  ##   Namespace: JString (required)
  ##            : The namespace that contains the assignment.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AssignmentName` field"
  var valid_21626574 = path.getOrDefault("AssignmentName")
  valid_21626574 = validateParameter(valid_21626574, JString, required = true,
                                   default = nil)
  if valid_21626574 != nil:
    section.add "AssignmentName", valid_21626574
  var valid_21626575 = path.getOrDefault("AwsAccountId")
  valid_21626575 = validateParameter(valid_21626575, JString, required = true,
                                   default = nil)
  if valid_21626575 != nil:
    section.add "AwsAccountId", valid_21626575
  var valid_21626576 = path.getOrDefault("Namespace")
  valid_21626576 = validateParameter(valid_21626576, JString, required = true,
                                   default = nil)
  if valid_21626576 != nil:
    section.add "Namespace", valid_21626576
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626577 = header.getOrDefault("X-Amz-Date")
  valid_21626577 = validateParameter(valid_21626577, JString, required = false,
                                   default = nil)
  if valid_21626577 != nil:
    section.add "X-Amz-Date", valid_21626577
  var valid_21626578 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626578 = validateParameter(valid_21626578, JString, required = false,
                                   default = nil)
  if valid_21626578 != nil:
    section.add "X-Amz-Security-Token", valid_21626578
  var valid_21626579 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626579 = validateParameter(valid_21626579, JString, required = false,
                                   default = nil)
  if valid_21626579 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626579
  var valid_21626580 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626580 = validateParameter(valid_21626580, JString, required = false,
                                   default = nil)
  if valid_21626580 != nil:
    section.add "X-Amz-Algorithm", valid_21626580
  var valid_21626581 = header.getOrDefault("X-Amz-Signature")
  valid_21626581 = validateParameter(valid_21626581, JString, required = false,
                                   default = nil)
  if valid_21626581 != nil:
    section.add "X-Amz-Signature", valid_21626581
  var valid_21626582 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626582 = validateParameter(valid_21626582, JString, required = false,
                                   default = nil)
  if valid_21626582 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626582
  var valid_21626583 = header.getOrDefault("X-Amz-Credential")
  valid_21626583 = validateParameter(valid_21626583, JString, required = false,
                                   default = nil)
  if valid_21626583 != nil:
    section.add "X-Amz-Credential", valid_21626583
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626584: Call_DeleteIAMPolicyAssignment_21626571;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an existing IAM policy assignment.
  ## 
  let valid = call_21626584.validator(path, query, header, formData, body, _)
  let scheme = call_21626584.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626584.makeUrl(scheme.get, call_21626584.host, call_21626584.base,
                               call_21626584.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626584, uri, valid, _)

proc call*(call_21626585: Call_DeleteIAMPolicyAssignment_21626571;
          AssignmentName: string; AwsAccountId: string; Namespace: string): Recallable =
  ## deleteIAMPolicyAssignment
  ## Deletes an existing IAM policy assignment.
  ##   AssignmentName: string (required)
  ##                 : The name of the assignment. 
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID where you want to delete the IAM policy assignment.
  ##   Namespace: string (required)
  ##            : The namespace that contains the assignment.
  var path_21626586 = newJObject()
  add(path_21626586, "AssignmentName", newJString(AssignmentName))
  add(path_21626586, "AwsAccountId", newJString(AwsAccountId))
  add(path_21626586, "Namespace", newJString(Namespace))
  result = call_21626585.call(path_21626586, nil, nil, nil, nil)

var deleteIAMPolicyAssignment* = Call_DeleteIAMPolicyAssignment_21626571(
    name: "deleteIAMPolicyAssignment", meth: HttpMethod.HttpDelete,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespace/{Namespace}/iam-policy-assignments/{AssignmentName}",
    validator: validate_DeleteIAMPolicyAssignment_21626572, base: "/",
    makeUrl: url_DeleteIAMPolicyAssignment_21626573,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUser_21626603 = ref object of OpenApiRestCall_21625435
proc url_UpdateUser_21626605(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "Namespace" in path, "`Namespace` is a required path parameter"
  assert "UserName" in path, "`UserName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/namespaces/"),
               (kind: VariableSegment, value: "Namespace"),
               (kind: ConstantSegment, value: "/users/"),
               (kind: VariableSegment, value: "UserName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateUser_21626604(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates an Amazon QuickSight user.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   UserName: JString (required)
  ##           : The Amazon QuickSight user name that you want to update.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_21626606 = path.getOrDefault("AwsAccountId")
  valid_21626606 = validateParameter(valid_21626606, JString, required = true,
                                   default = nil)
  if valid_21626606 != nil:
    section.add "AwsAccountId", valid_21626606
  var valid_21626607 = path.getOrDefault("UserName")
  valid_21626607 = validateParameter(valid_21626607, JString, required = true,
                                   default = nil)
  if valid_21626607 != nil:
    section.add "UserName", valid_21626607
  var valid_21626608 = path.getOrDefault("Namespace")
  valid_21626608 = validateParameter(valid_21626608, JString, required = true,
                                   default = nil)
  if valid_21626608 != nil:
    section.add "Namespace", valid_21626608
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626609 = header.getOrDefault("X-Amz-Date")
  valid_21626609 = validateParameter(valid_21626609, JString, required = false,
                                   default = nil)
  if valid_21626609 != nil:
    section.add "X-Amz-Date", valid_21626609
  var valid_21626610 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626610 = validateParameter(valid_21626610, JString, required = false,
                                   default = nil)
  if valid_21626610 != nil:
    section.add "X-Amz-Security-Token", valid_21626610
  var valid_21626611 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626611 = validateParameter(valid_21626611, JString, required = false,
                                   default = nil)
  if valid_21626611 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626611
  var valid_21626612 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626612 = validateParameter(valid_21626612, JString, required = false,
                                   default = nil)
  if valid_21626612 != nil:
    section.add "X-Amz-Algorithm", valid_21626612
  var valid_21626613 = header.getOrDefault("X-Amz-Signature")
  valid_21626613 = validateParameter(valid_21626613, JString, required = false,
                                   default = nil)
  if valid_21626613 != nil:
    section.add "X-Amz-Signature", valid_21626613
  var valid_21626614 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626614 = validateParameter(valid_21626614, JString, required = false,
                                   default = nil)
  if valid_21626614 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626614
  var valid_21626615 = header.getOrDefault("X-Amz-Credential")
  valid_21626615 = validateParameter(valid_21626615, JString, required = false,
                                   default = nil)
  if valid_21626615 != nil:
    section.add "X-Amz-Credential", valid_21626615
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626617: Call_UpdateUser_21626603; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an Amazon QuickSight user.
  ## 
  let valid = call_21626617.validator(path, query, header, formData, body, _)
  let scheme = call_21626617.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626617.makeUrl(scheme.get, call_21626617.host, call_21626617.base,
                               call_21626617.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626617, uri, valid, _)

proc call*(call_21626618: Call_UpdateUser_21626603; AwsAccountId: string;
          body: JsonNode; UserName: string; Namespace: string): Recallable =
  ## updateUser
  ## Updates an Amazon QuickSight user.
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   body: JObject (required)
  ##   UserName: string (required)
  ##           : The Amazon QuickSight user name that you want to update.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  var path_21626619 = newJObject()
  var body_21626620 = newJObject()
  add(path_21626619, "AwsAccountId", newJString(AwsAccountId))
  if body != nil:
    body_21626620 = body
  add(path_21626619, "UserName", newJString(UserName))
  add(path_21626619, "Namespace", newJString(Namespace))
  result = call_21626618.call(path_21626619, nil, nil, nil, body_21626620)

var updateUser* = Call_UpdateUser_21626603(name: "updateUser",
                                        meth: HttpMethod.HttpPut,
                                        host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}",
                                        validator: validate_UpdateUser_21626604,
                                        base: "/", makeUrl: url_UpdateUser_21626605,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUser_21626587 = ref object of OpenApiRestCall_21625435
proc url_DescribeUser_21626589(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "Namespace" in path, "`Namespace` is a required path parameter"
  assert "UserName" in path, "`UserName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/namespaces/"),
               (kind: VariableSegment, value: "Namespace"),
               (kind: ConstantSegment, value: "/users/"),
               (kind: VariableSegment, value: "UserName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeUser_21626588(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Returns information about a user, given the user name. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   UserName: JString (required)
  ##           : The name of the user that you want to describe.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_21626590 = path.getOrDefault("AwsAccountId")
  valid_21626590 = validateParameter(valid_21626590, JString, required = true,
                                   default = nil)
  if valid_21626590 != nil:
    section.add "AwsAccountId", valid_21626590
  var valid_21626591 = path.getOrDefault("UserName")
  valid_21626591 = validateParameter(valid_21626591, JString, required = true,
                                   default = nil)
  if valid_21626591 != nil:
    section.add "UserName", valid_21626591
  var valid_21626592 = path.getOrDefault("Namespace")
  valid_21626592 = validateParameter(valid_21626592, JString, required = true,
                                   default = nil)
  if valid_21626592 != nil:
    section.add "Namespace", valid_21626592
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626593 = header.getOrDefault("X-Amz-Date")
  valid_21626593 = validateParameter(valid_21626593, JString, required = false,
                                   default = nil)
  if valid_21626593 != nil:
    section.add "X-Amz-Date", valid_21626593
  var valid_21626594 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626594 = validateParameter(valid_21626594, JString, required = false,
                                   default = nil)
  if valid_21626594 != nil:
    section.add "X-Amz-Security-Token", valid_21626594
  var valid_21626595 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626595 = validateParameter(valid_21626595, JString, required = false,
                                   default = nil)
  if valid_21626595 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626595
  var valid_21626596 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626596 = validateParameter(valid_21626596, JString, required = false,
                                   default = nil)
  if valid_21626596 != nil:
    section.add "X-Amz-Algorithm", valid_21626596
  var valid_21626597 = header.getOrDefault("X-Amz-Signature")
  valid_21626597 = validateParameter(valid_21626597, JString, required = false,
                                   default = nil)
  if valid_21626597 != nil:
    section.add "X-Amz-Signature", valid_21626597
  var valid_21626598 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626598 = validateParameter(valid_21626598, JString, required = false,
                                   default = nil)
  if valid_21626598 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626598
  var valid_21626599 = header.getOrDefault("X-Amz-Credential")
  valid_21626599 = validateParameter(valid_21626599, JString, required = false,
                                   default = nil)
  if valid_21626599 != nil:
    section.add "X-Amz-Credential", valid_21626599
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626600: Call_DescribeUser_21626587; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about a user, given the user name. 
  ## 
  let valid = call_21626600.validator(path, query, header, formData, body, _)
  let scheme = call_21626600.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626600.makeUrl(scheme.get, call_21626600.host, call_21626600.base,
                               call_21626600.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626600, uri, valid, _)

proc call*(call_21626601: Call_DescribeUser_21626587; AwsAccountId: string;
          UserName: string; Namespace: string): Recallable =
  ## describeUser
  ## Returns information about a user, given the user name. 
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   UserName: string (required)
  ##           : The name of the user that you want to describe.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  var path_21626602 = newJObject()
  add(path_21626602, "AwsAccountId", newJString(AwsAccountId))
  add(path_21626602, "UserName", newJString(UserName))
  add(path_21626602, "Namespace", newJString(Namespace))
  result = call_21626601.call(path_21626602, nil, nil, nil, nil)

var describeUser* = Call_DescribeUser_21626587(name: "describeUser",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}",
    validator: validate_DescribeUser_21626588, base: "/", makeUrl: url_DescribeUser_21626589,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_21626621 = ref object of OpenApiRestCall_21625435
proc url_DeleteUser_21626623(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "Namespace" in path, "`Namespace` is a required path parameter"
  assert "UserName" in path, "`UserName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/namespaces/"),
               (kind: VariableSegment, value: "Namespace"),
               (kind: ConstantSegment, value: "/users/"),
               (kind: VariableSegment, value: "UserName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteUser_21626622(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes the Amazon QuickSight user that is associated with the identity of the AWS Identity and Access Management (IAM) user or role that's making the call. The IAM user isn't deleted as a result of this call. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   UserName: JString (required)
  ##           : The name of the user that you want to delete.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_21626624 = path.getOrDefault("AwsAccountId")
  valid_21626624 = validateParameter(valid_21626624, JString, required = true,
                                   default = nil)
  if valid_21626624 != nil:
    section.add "AwsAccountId", valid_21626624
  var valid_21626625 = path.getOrDefault("UserName")
  valid_21626625 = validateParameter(valid_21626625, JString, required = true,
                                   default = nil)
  if valid_21626625 != nil:
    section.add "UserName", valid_21626625
  var valid_21626626 = path.getOrDefault("Namespace")
  valid_21626626 = validateParameter(valid_21626626, JString, required = true,
                                   default = nil)
  if valid_21626626 != nil:
    section.add "Namespace", valid_21626626
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626627 = header.getOrDefault("X-Amz-Date")
  valid_21626627 = validateParameter(valid_21626627, JString, required = false,
                                   default = nil)
  if valid_21626627 != nil:
    section.add "X-Amz-Date", valid_21626627
  var valid_21626628 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626628 = validateParameter(valid_21626628, JString, required = false,
                                   default = nil)
  if valid_21626628 != nil:
    section.add "X-Amz-Security-Token", valid_21626628
  var valid_21626629 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626629 = validateParameter(valid_21626629, JString, required = false,
                                   default = nil)
  if valid_21626629 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626629
  var valid_21626630 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626630 = validateParameter(valid_21626630, JString, required = false,
                                   default = nil)
  if valid_21626630 != nil:
    section.add "X-Amz-Algorithm", valid_21626630
  var valid_21626631 = header.getOrDefault("X-Amz-Signature")
  valid_21626631 = validateParameter(valid_21626631, JString, required = false,
                                   default = nil)
  if valid_21626631 != nil:
    section.add "X-Amz-Signature", valid_21626631
  var valid_21626632 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626632 = validateParameter(valid_21626632, JString, required = false,
                                   default = nil)
  if valid_21626632 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626632
  var valid_21626633 = header.getOrDefault("X-Amz-Credential")
  valid_21626633 = validateParameter(valid_21626633, JString, required = false,
                                   default = nil)
  if valid_21626633 != nil:
    section.add "X-Amz-Credential", valid_21626633
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626634: Call_DeleteUser_21626621; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the Amazon QuickSight user that is associated with the identity of the AWS Identity and Access Management (IAM) user or role that's making the call. The IAM user isn't deleted as a result of this call. 
  ## 
  let valid = call_21626634.validator(path, query, header, formData, body, _)
  let scheme = call_21626634.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626634.makeUrl(scheme.get, call_21626634.host, call_21626634.base,
                               call_21626634.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626634, uri, valid, _)

proc call*(call_21626635: Call_DeleteUser_21626621; AwsAccountId: string;
          UserName: string; Namespace: string): Recallable =
  ## deleteUser
  ## Deletes the Amazon QuickSight user that is associated with the identity of the AWS Identity and Access Management (IAM) user or role that's making the call. The IAM user isn't deleted as a result of this call. 
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   UserName: string (required)
  ##           : The name of the user that you want to delete.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  var path_21626636 = newJObject()
  add(path_21626636, "AwsAccountId", newJString(AwsAccountId))
  add(path_21626636, "UserName", newJString(UserName))
  add(path_21626636, "Namespace", newJString(Namespace))
  result = call_21626635.call(path_21626636, nil, nil, nil, nil)

var deleteUser* = Call_DeleteUser_21626621(name: "deleteUser",
                                        meth: HttpMethod.HttpDelete,
                                        host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}",
                                        validator: validate_DeleteUser_21626622,
                                        base: "/", makeUrl: url_DeleteUser_21626623,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserByPrincipalId_21626637 = ref object of OpenApiRestCall_21625435
proc url_DeleteUserByPrincipalId_21626639(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "Namespace" in path, "`Namespace` is a required path parameter"
  assert "PrincipalId" in path, "`PrincipalId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/namespaces/"),
               (kind: VariableSegment, value: "Namespace"),
               (kind: ConstantSegment, value: "/user-principals/"),
               (kind: VariableSegment, value: "PrincipalId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteUserByPrincipalId_21626638(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a user identified by its principal ID. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   PrincipalId: JString (required)
  ##              : The principal ID of the user.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_21626640 = path.getOrDefault("AwsAccountId")
  valid_21626640 = validateParameter(valid_21626640, JString, required = true,
                                   default = nil)
  if valid_21626640 != nil:
    section.add "AwsAccountId", valid_21626640
  var valid_21626641 = path.getOrDefault("PrincipalId")
  valid_21626641 = validateParameter(valid_21626641, JString, required = true,
                                   default = nil)
  if valid_21626641 != nil:
    section.add "PrincipalId", valid_21626641
  var valid_21626642 = path.getOrDefault("Namespace")
  valid_21626642 = validateParameter(valid_21626642, JString, required = true,
                                   default = nil)
  if valid_21626642 != nil:
    section.add "Namespace", valid_21626642
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626643 = header.getOrDefault("X-Amz-Date")
  valid_21626643 = validateParameter(valid_21626643, JString, required = false,
                                   default = nil)
  if valid_21626643 != nil:
    section.add "X-Amz-Date", valid_21626643
  var valid_21626644 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626644 = validateParameter(valid_21626644, JString, required = false,
                                   default = nil)
  if valid_21626644 != nil:
    section.add "X-Amz-Security-Token", valid_21626644
  var valid_21626645 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626645 = validateParameter(valid_21626645, JString, required = false,
                                   default = nil)
  if valid_21626645 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626645
  var valid_21626646 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626646 = validateParameter(valid_21626646, JString, required = false,
                                   default = nil)
  if valid_21626646 != nil:
    section.add "X-Amz-Algorithm", valid_21626646
  var valid_21626647 = header.getOrDefault("X-Amz-Signature")
  valid_21626647 = validateParameter(valid_21626647, JString, required = false,
                                   default = nil)
  if valid_21626647 != nil:
    section.add "X-Amz-Signature", valid_21626647
  var valid_21626648 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626648 = validateParameter(valid_21626648, JString, required = false,
                                   default = nil)
  if valid_21626648 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626648
  var valid_21626649 = header.getOrDefault("X-Amz-Credential")
  valid_21626649 = validateParameter(valid_21626649, JString, required = false,
                                   default = nil)
  if valid_21626649 != nil:
    section.add "X-Amz-Credential", valid_21626649
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626650: Call_DeleteUserByPrincipalId_21626637;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a user identified by its principal ID. 
  ## 
  let valid = call_21626650.validator(path, query, header, formData, body, _)
  let scheme = call_21626650.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626650.makeUrl(scheme.get, call_21626650.host, call_21626650.base,
                               call_21626650.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626650, uri, valid, _)

proc call*(call_21626651: Call_DeleteUserByPrincipalId_21626637;
          AwsAccountId: string; PrincipalId: string; Namespace: string): Recallable =
  ## deleteUserByPrincipalId
  ## Deletes a user identified by its principal ID. 
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   PrincipalId: string (required)
  ##              : The principal ID of the user.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  var path_21626652 = newJObject()
  add(path_21626652, "AwsAccountId", newJString(AwsAccountId))
  add(path_21626652, "PrincipalId", newJString(PrincipalId))
  add(path_21626652, "Namespace", newJString(Namespace))
  result = call_21626651.call(path_21626652, nil, nil, nil, nil)

var deleteUserByPrincipalId* = Call_DeleteUserByPrincipalId_21626637(
    name: "deleteUserByPrincipalId", meth: HttpMethod.HttpDelete,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/user-principals/{PrincipalId}",
    validator: validate_DeleteUserByPrincipalId_21626638, base: "/",
    makeUrl: url_DeleteUserByPrincipalId_21626639,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDashboardPermissions_21626668 = ref object of OpenApiRestCall_21625435
proc url_UpdateDashboardPermissions_21626670(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "DashboardId" in path, "`DashboardId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/dashboards/"),
               (kind: VariableSegment, value: "DashboardId"),
               (kind: ConstantSegment, value: "/permissions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDashboardPermissions_21626669(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates read and write permissions on a dashboard.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account that contains the dashboard whose permissions you're updating.
  ##   DashboardId: JString (required)
  ##              : The ID for the dashboard.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_21626671 = path.getOrDefault("AwsAccountId")
  valid_21626671 = validateParameter(valid_21626671, JString, required = true,
                                   default = nil)
  if valid_21626671 != nil:
    section.add "AwsAccountId", valid_21626671
  var valid_21626672 = path.getOrDefault("DashboardId")
  valid_21626672 = validateParameter(valid_21626672, JString, required = true,
                                   default = nil)
  if valid_21626672 != nil:
    section.add "DashboardId", valid_21626672
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626673 = header.getOrDefault("X-Amz-Date")
  valid_21626673 = validateParameter(valid_21626673, JString, required = false,
                                   default = nil)
  if valid_21626673 != nil:
    section.add "X-Amz-Date", valid_21626673
  var valid_21626674 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626674 = validateParameter(valid_21626674, JString, required = false,
                                   default = nil)
  if valid_21626674 != nil:
    section.add "X-Amz-Security-Token", valid_21626674
  var valid_21626675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626675 = validateParameter(valid_21626675, JString, required = false,
                                   default = nil)
  if valid_21626675 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626675
  var valid_21626676 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626676 = validateParameter(valid_21626676, JString, required = false,
                                   default = nil)
  if valid_21626676 != nil:
    section.add "X-Amz-Algorithm", valid_21626676
  var valid_21626677 = header.getOrDefault("X-Amz-Signature")
  valid_21626677 = validateParameter(valid_21626677, JString, required = false,
                                   default = nil)
  if valid_21626677 != nil:
    section.add "X-Amz-Signature", valid_21626677
  var valid_21626678 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626678 = validateParameter(valid_21626678, JString, required = false,
                                   default = nil)
  if valid_21626678 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626678
  var valid_21626679 = header.getOrDefault("X-Amz-Credential")
  valid_21626679 = validateParameter(valid_21626679, JString, required = false,
                                   default = nil)
  if valid_21626679 != nil:
    section.add "X-Amz-Credential", valid_21626679
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626681: Call_UpdateDashboardPermissions_21626668;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates read and write permissions on a dashboard.
  ## 
  let valid = call_21626681.validator(path, query, header, formData, body, _)
  let scheme = call_21626681.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626681.makeUrl(scheme.get, call_21626681.host, call_21626681.base,
                               call_21626681.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626681, uri, valid, _)

proc call*(call_21626682: Call_UpdateDashboardPermissions_21626668;
          AwsAccountId: string; DashboardId: string; body: JsonNode): Recallable =
  ## updateDashboardPermissions
  ## Updates read and write permissions on a dashboard.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the dashboard whose permissions you're updating.
  ##   DashboardId: string (required)
  ##              : The ID for the dashboard.
  ##   body: JObject (required)
  var path_21626683 = newJObject()
  var body_21626684 = newJObject()
  add(path_21626683, "AwsAccountId", newJString(AwsAccountId))
  add(path_21626683, "DashboardId", newJString(DashboardId))
  if body != nil:
    body_21626684 = body
  result = call_21626682.call(path_21626683, nil, nil, nil, body_21626684)

var updateDashboardPermissions* = Call_UpdateDashboardPermissions_21626668(
    name: "updateDashboardPermissions", meth: HttpMethod.HttpPut,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}/permissions",
    validator: validate_UpdateDashboardPermissions_21626669, base: "/",
    makeUrl: url_UpdateDashboardPermissions_21626670,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDashboardPermissions_21626653 = ref object of OpenApiRestCall_21625435
proc url_DescribeDashboardPermissions_21626655(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "DashboardId" in path, "`DashboardId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/dashboards/"),
               (kind: VariableSegment, value: "DashboardId"),
               (kind: ConstantSegment, value: "/permissions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeDashboardPermissions_21626654(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Describes read and write permissions for a dashboard.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account that contains the dashboard that you're describing permissions for.
  ##   DashboardId: JString (required)
  ##              : The ID for the dashboard, also added to the IAM policy.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_21626656 = path.getOrDefault("AwsAccountId")
  valid_21626656 = validateParameter(valid_21626656, JString, required = true,
                                   default = nil)
  if valid_21626656 != nil:
    section.add "AwsAccountId", valid_21626656
  var valid_21626657 = path.getOrDefault("DashboardId")
  valid_21626657 = validateParameter(valid_21626657, JString, required = true,
                                   default = nil)
  if valid_21626657 != nil:
    section.add "DashboardId", valid_21626657
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626658 = header.getOrDefault("X-Amz-Date")
  valid_21626658 = validateParameter(valid_21626658, JString, required = false,
                                   default = nil)
  if valid_21626658 != nil:
    section.add "X-Amz-Date", valid_21626658
  var valid_21626659 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626659 = validateParameter(valid_21626659, JString, required = false,
                                   default = nil)
  if valid_21626659 != nil:
    section.add "X-Amz-Security-Token", valid_21626659
  var valid_21626660 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626660 = validateParameter(valid_21626660, JString, required = false,
                                   default = nil)
  if valid_21626660 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626660
  var valid_21626661 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626661 = validateParameter(valid_21626661, JString, required = false,
                                   default = nil)
  if valid_21626661 != nil:
    section.add "X-Amz-Algorithm", valid_21626661
  var valid_21626662 = header.getOrDefault("X-Amz-Signature")
  valid_21626662 = validateParameter(valid_21626662, JString, required = false,
                                   default = nil)
  if valid_21626662 != nil:
    section.add "X-Amz-Signature", valid_21626662
  var valid_21626663 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626663 = validateParameter(valid_21626663, JString, required = false,
                                   default = nil)
  if valid_21626663 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626663
  var valid_21626664 = header.getOrDefault("X-Amz-Credential")
  valid_21626664 = validateParameter(valid_21626664, JString, required = false,
                                   default = nil)
  if valid_21626664 != nil:
    section.add "X-Amz-Credential", valid_21626664
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626665: Call_DescribeDashboardPermissions_21626653;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes read and write permissions for a dashboard.
  ## 
  let valid = call_21626665.validator(path, query, header, formData, body, _)
  let scheme = call_21626665.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626665.makeUrl(scheme.get, call_21626665.host, call_21626665.base,
                               call_21626665.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626665, uri, valid, _)

proc call*(call_21626666: Call_DescribeDashboardPermissions_21626653;
          AwsAccountId: string; DashboardId: string): Recallable =
  ## describeDashboardPermissions
  ## Describes read and write permissions for a dashboard.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the dashboard that you're describing permissions for.
  ##   DashboardId: string (required)
  ##              : The ID for the dashboard, also added to the IAM policy.
  var path_21626667 = newJObject()
  add(path_21626667, "AwsAccountId", newJString(AwsAccountId))
  add(path_21626667, "DashboardId", newJString(DashboardId))
  result = call_21626666.call(path_21626667, nil, nil, nil, nil)

var describeDashboardPermissions* = Call_DescribeDashboardPermissions_21626653(
    name: "describeDashboardPermissions", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}/permissions",
    validator: validate_DescribeDashboardPermissions_21626654, base: "/",
    makeUrl: url_DescribeDashboardPermissions_21626655,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDataSetPermissions_21626700 = ref object of OpenApiRestCall_21625435
proc url_UpdateDataSetPermissions_21626702(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/data-sets/"),
               (kind: VariableSegment, value: "DataSetId"),
               (kind: ConstantSegment, value: "/permissions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDataSetPermissions_21626701(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Updates the permissions on a dataset.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:dataset/data-set-id</code>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID.
  ##   DataSetId: JString (required)
  ##            : The ID for the dataset whose permissions you want to update. This ID is unique per AWS Region for each AWS account.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_21626703 = path.getOrDefault("AwsAccountId")
  valid_21626703 = validateParameter(valid_21626703, JString, required = true,
                                   default = nil)
  if valid_21626703 != nil:
    section.add "AwsAccountId", valid_21626703
  var valid_21626704 = path.getOrDefault("DataSetId")
  valid_21626704 = validateParameter(valid_21626704, JString, required = true,
                                   default = nil)
  if valid_21626704 != nil:
    section.add "DataSetId", valid_21626704
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626705 = header.getOrDefault("X-Amz-Date")
  valid_21626705 = validateParameter(valid_21626705, JString, required = false,
                                   default = nil)
  if valid_21626705 != nil:
    section.add "X-Amz-Date", valid_21626705
  var valid_21626706 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626706 = validateParameter(valid_21626706, JString, required = false,
                                   default = nil)
  if valid_21626706 != nil:
    section.add "X-Amz-Security-Token", valid_21626706
  var valid_21626707 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626707 = validateParameter(valid_21626707, JString, required = false,
                                   default = nil)
  if valid_21626707 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626707
  var valid_21626708 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626708 = validateParameter(valid_21626708, JString, required = false,
                                   default = nil)
  if valid_21626708 != nil:
    section.add "X-Amz-Algorithm", valid_21626708
  var valid_21626709 = header.getOrDefault("X-Amz-Signature")
  valid_21626709 = validateParameter(valid_21626709, JString, required = false,
                                   default = nil)
  if valid_21626709 != nil:
    section.add "X-Amz-Signature", valid_21626709
  var valid_21626710 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626710 = validateParameter(valid_21626710, JString, required = false,
                                   default = nil)
  if valid_21626710 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626710
  var valid_21626711 = header.getOrDefault("X-Amz-Credential")
  valid_21626711 = validateParameter(valid_21626711, JString, required = false,
                                   default = nil)
  if valid_21626711 != nil:
    section.add "X-Amz-Credential", valid_21626711
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626713: Call_UpdateDataSetPermissions_21626700;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates the permissions on a dataset.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:dataset/data-set-id</code>.</p>
  ## 
  let valid = call_21626713.validator(path, query, header, formData, body, _)
  let scheme = call_21626713.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626713.makeUrl(scheme.get, call_21626713.host, call_21626713.base,
                               call_21626713.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626713, uri, valid, _)

proc call*(call_21626714: Call_UpdateDataSetPermissions_21626700;
          AwsAccountId: string; body: JsonNode; DataSetId: string): Recallable =
  ## updateDataSetPermissions
  ## <p>Updates the permissions on a dataset.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:dataset/data-set-id</code>.</p>
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   body: JObject (required)
  ##   DataSetId: string (required)
  ##            : The ID for the dataset whose permissions you want to update. This ID is unique per AWS Region for each AWS account.
  var path_21626715 = newJObject()
  var body_21626716 = newJObject()
  add(path_21626715, "AwsAccountId", newJString(AwsAccountId))
  if body != nil:
    body_21626716 = body
  add(path_21626715, "DataSetId", newJString(DataSetId))
  result = call_21626714.call(path_21626715, nil, nil, nil, body_21626716)

var updateDataSetPermissions* = Call_UpdateDataSetPermissions_21626700(
    name: "updateDataSetPermissions", meth: HttpMethod.HttpPost,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}/permissions",
    validator: validate_UpdateDataSetPermissions_21626701, base: "/",
    makeUrl: url_UpdateDataSetPermissions_21626702,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDataSetPermissions_21626685 = ref object of OpenApiRestCall_21625435
proc url_DescribeDataSetPermissions_21626687(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/data-sets/"),
               (kind: VariableSegment, value: "DataSetId"),
               (kind: ConstantSegment, value: "/permissions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeDataSetPermissions_21626686(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Describes the permissions on a dataset.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:dataset/data-set-id</code>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID.
  ##   DataSetId: JString (required)
  ##            : The ID for the dataset that you want to create. This ID is unique per AWS Region for each AWS account.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_21626688 = path.getOrDefault("AwsAccountId")
  valid_21626688 = validateParameter(valid_21626688, JString, required = true,
                                   default = nil)
  if valid_21626688 != nil:
    section.add "AwsAccountId", valid_21626688
  var valid_21626689 = path.getOrDefault("DataSetId")
  valid_21626689 = validateParameter(valid_21626689, JString, required = true,
                                   default = nil)
  if valid_21626689 != nil:
    section.add "DataSetId", valid_21626689
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626690 = header.getOrDefault("X-Amz-Date")
  valid_21626690 = validateParameter(valid_21626690, JString, required = false,
                                   default = nil)
  if valid_21626690 != nil:
    section.add "X-Amz-Date", valid_21626690
  var valid_21626691 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626691 = validateParameter(valid_21626691, JString, required = false,
                                   default = nil)
  if valid_21626691 != nil:
    section.add "X-Amz-Security-Token", valid_21626691
  var valid_21626692 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626692 = validateParameter(valid_21626692, JString, required = false,
                                   default = nil)
  if valid_21626692 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626692
  var valid_21626693 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626693 = validateParameter(valid_21626693, JString, required = false,
                                   default = nil)
  if valid_21626693 != nil:
    section.add "X-Amz-Algorithm", valid_21626693
  var valid_21626694 = header.getOrDefault("X-Amz-Signature")
  valid_21626694 = validateParameter(valid_21626694, JString, required = false,
                                   default = nil)
  if valid_21626694 != nil:
    section.add "X-Amz-Signature", valid_21626694
  var valid_21626695 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626695 = validateParameter(valid_21626695, JString, required = false,
                                   default = nil)
  if valid_21626695 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626695
  var valid_21626696 = header.getOrDefault("X-Amz-Credential")
  valid_21626696 = validateParameter(valid_21626696, JString, required = false,
                                   default = nil)
  if valid_21626696 != nil:
    section.add "X-Amz-Credential", valid_21626696
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626697: Call_DescribeDataSetPermissions_21626685;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Describes the permissions on a dataset.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:dataset/data-set-id</code>.</p>
  ## 
  let valid = call_21626697.validator(path, query, header, formData, body, _)
  let scheme = call_21626697.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626697.makeUrl(scheme.get, call_21626697.host, call_21626697.base,
                               call_21626697.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626697, uri, valid, _)

proc call*(call_21626698: Call_DescribeDataSetPermissions_21626685;
          AwsAccountId: string; DataSetId: string): Recallable =
  ## describeDataSetPermissions
  ## <p>Describes the permissions on a dataset.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:dataset/data-set-id</code>.</p>
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSetId: string (required)
  ##            : The ID for the dataset that you want to create. This ID is unique per AWS Region for each AWS account.
  var path_21626699 = newJObject()
  add(path_21626699, "AwsAccountId", newJString(AwsAccountId))
  add(path_21626699, "DataSetId", newJString(DataSetId))
  result = call_21626698.call(path_21626699, nil, nil, nil, nil)

var describeDataSetPermissions* = Call_DescribeDataSetPermissions_21626685(
    name: "describeDataSetPermissions", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}/permissions",
    validator: validate_DescribeDataSetPermissions_21626686, base: "/",
    makeUrl: url_DescribeDataSetPermissions_21626687,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDataSourcePermissions_21626732 = ref object of OpenApiRestCall_21625435
proc url_UpdateDataSourcePermissions_21626734(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "DataSourceId" in path, "`DataSourceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/data-sources/"),
               (kind: VariableSegment, value: "DataSourceId"),
               (kind: ConstantSegment, value: "/permissions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDataSourcePermissions_21626733(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates the permissions to a data source.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID.
  ##   DataSourceId: JString (required)
  ##               : The ID of the data source. This ID is unique per AWS Region for each AWS account. 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_21626735 = path.getOrDefault("AwsAccountId")
  valid_21626735 = validateParameter(valid_21626735, JString, required = true,
                                   default = nil)
  if valid_21626735 != nil:
    section.add "AwsAccountId", valid_21626735
  var valid_21626736 = path.getOrDefault("DataSourceId")
  valid_21626736 = validateParameter(valid_21626736, JString, required = true,
                                   default = nil)
  if valid_21626736 != nil:
    section.add "DataSourceId", valid_21626736
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626737 = header.getOrDefault("X-Amz-Date")
  valid_21626737 = validateParameter(valid_21626737, JString, required = false,
                                   default = nil)
  if valid_21626737 != nil:
    section.add "X-Amz-Date", valid_21626737
  var valid_21626738 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626738 = validateParameter(valid_21626738, JString, required = false,
                                   default = nil)
  if valid_21626738 != nil:
    section.add "X-Amz-Security-Token", valid_21626738
  var valid_21626739 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626739 = validateParameter(valid_21626739, JString, required = false,
                                   default = nil)
  if valid_21626739 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626739
  var valid_21626740 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626740 = validateParameter(valid_21626740, JString, required = false,
                                   default = nil)
  if valid_21626740 != nil:
    section.add "X-Amz-Algorithm", valid_21626740
  var valid_21626741 = header.getOrDefault("X-Amz-Signature")
  valid_21626741 = validateParameter(valid_21626741, JString, required = false,
                                   default = nil)
  if valid_21626741 != nil:
    section.add "X-Amz-Signature", valid_21626741
  var valid_21626742 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626742 = validateParameter(valid_21626742, JString, required = false,
                                   default = nil)
  if valid_21626742 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626742
  var valid_21626743 = header.getOrDefault("X-Amz-Credential")
  valid_21626743 = validateParameter(valid_21626743, JString, required = false,
                                   default = nil)
  if valid_21626743 != nil:
    section.add "X-Amz-Credential", valid_21626743
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626745: Call_UpdateDataSourcePermissions_21626732;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the permissions to a data source.
  ## 
  let valid = call_21626745.validator(path, query, header, formData, body, _)
  let scheme = call_21626745.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626745.makeUrl(scheme.get, call_21626745.host, call_21626745.base,
                               call_21626745.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626745, uri, valid, _)

proc call*(call_21626746: Call_UpdateDataSourcePermissions_21626732;
          AwsAccountId: string; DataSourceId: string; body: JsonNode): Recallable =
  ## updateDataSourcePermissions
  ## Updates the permissions to a data source.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSourceId: string (required)
  ##               : The ID of the data source. This ID is unique per AWS Region for each AWS account. 
  ##   body: JObject (required)
  var path_21626747 = newJObject()
  var body_21626748 = newJObject()
  add(path_21626747, "AwsAccountId", newJString(AwsAccountId))
  add(path_21626747, "DataSourceId", newJString(DataSourceId))
  if body != nil:
    body_21626748 = body
  result = call_21626746.call(path_21626747, nil, nil, nil, body_21626748)

var updateDataSourcePermissions* = Call_UpdateDataSourcePermissions_21626732(
    name: "updateDataSourcePermissions", meth: HttpMethod.HttpPost,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sources/{DataSourceId}/permissions",
    validator: validate_UpdateDataSourcePermissions_21626733, base: "/",
    makeUrl: url_UpdateDataSourcePermissions_21626734,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDataSourcePermissions_21626717 = ref object of OpenApiRestCall_21625435
proc url_DescribeDataSourcePermissions_21626719(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "DataSourceId" in path, "`DataSourceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/data-sources/"),
               (kind: VariableSegment, value: "DataSourceId"),
               (kind: ConstantSegment, value: "/permissions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeDataSourcePermissions_21626718(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Describes the resource permissions for a data source.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID.
  ##   DataSourceId: JString (required)
  ##               : The ID of the data source. This ID is unique per AWS Region for each AWS account.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_21626720 = path.getOrDefault("AwsAccountId")
  valid_21626720 = validateParameter(valid_21626720, JString, required = true,
                                   default = nil)
  if valid_21626720 != nil:
    section.add "AwsAccountId", valid_21626720
  var valid_21626721 = path.getOrDefault("DataSourceId")
  valid_21626721 = validateParameter(valid_21626721, JString, required = true,
                                   default = nil)
  if valid_21626721 != nil:
    section.add "DataSourceId", valid_21626721
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626722 = header.getOrDefault("X-Amz-Date")
  valid_21626722 = validateParameter(valid_21626722, JString, required = false,
                                   default = nil)
  if valid_21626722 != nil:
    section.add "X-Amz-Date", valid_21626722
  var valid_21626723 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626723 = validateParameter(valid_21626723, JString, required = false,
                                   default = nil)
  if valid_21626723 != nil:
    section.add "X-Amz-Security-Token", valid_21626723
  var valid_21626724 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626724 = validateParameter(valid_21626724, JString, required = false,
                                   default = nil)
  if valid_21626724 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626724
  var valid_21626725 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626725 = validateParameter(valid_21626725, JString, required = false,
                                   default = nil)
  if valid_21626725 != nil:
    section.add "X-Amz-Algorithm", valid_21626725
  var valid_21626726 = header.getOrDefault("X-Amz-Signature")
  valid_21626726 = validateParameter(valid_21626726, JString, required = false,
                                   default = nil)
  if valid_21626726 != nil:
    section.add "X-Amz-Signature", valid_21626726
  var valid_21626727 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626727 = validateParameter(valid_21626727, JString, required = false,
                                   default = nil)
  if valid_21626727 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626727
  var valid_21626728 = header.getOrDefault("X-Amz-Credential")
  valid_21626728 = validateParameter(valid_21626728, JString, required = false,
                                   default = nil)
  if valid_21626728 != nil:
    section.add "X-Amz-Credential", valid_21626728
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626729: Call_DescribeDataSourcePermissions_21626717;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the resource permissions for a data source.
  ## 
  let valid = call_21626729.validator(path, query, header, formData, body, _)
  let scheme = call_21626729.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626729.makeUrl(scheme.get, call_21626729.host, call_21626729.base,
                               call_21626729.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626729, uri, valid, _)

proc call*(call_21626730: Call_DescribeDataSourcePermissions_21626717;
          AwsAccountId: string; DataSourceId: string): Recallable =
  ## describeDataSourcePermissions
  ## Describes the resource permissions for a data source.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSourceId: string (required)
  ##               : The ID of the data source. This ID is unique per AWS Region for each AWS account.
  var path_21626731 = newJObject()
  add(path_21626731, "AwsAccountId", newJString(AwsAccountId))
  add(path_21626731, "DataSourceId", newJString(DataSourceId))
  result = call_21626730.call(path_21626731, nil, nil, nil, nil)

var describeDataSourcePermissions* = Call_DescribeDataSourcePermissions_21626717(
    name: "describeDataSourcePermissions", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sources/{DataSourceId}/permissions",
    validator: validate_DescribeDataSourcePermissions_21626718, base: "/",
    makeUrl: url_DescribeDataSourcePermissions_21626719,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIAMPolicyAssignment_21626765 = ref object of OpenApiRestCall_21625435
proc url_UpdateIAMPolicyAssignment_21626767(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "Namespace" in path, "`Namespace` is a required path parameter"
  assert "AssignmentName" in path, "`AssignmentName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/namespaces/"),
               (kind: VariableSegment, value: "Namespace"),
               (kind: ConstantSegment, value: "/iam-policy-assignments/"),
               (kind: VariableSegment, value: "AssignmentName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateIAMPolicyAssignment_21626766(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates an existing IAM policy assignment. This operation updates only the optional parameter or parameters that are specified in the request.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AssignmentName: JString (required)
  ##                 : The name of the assignment. This name must be unique within an AWS account.
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account that contains the IAM policy assignment.
  ##   Namespace: JString (required)
  ##            : The namespace of the assignment.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AssignmentName` field"
  var valid_21626768 = path.getOrDefault("AssignmentName")
  valid_21626768 = validateParameter(valid_21626768, JString, required = true,
                                   default = nil)
  if valid_21626768 != nil:
    section.add "AssignmentName", valid_21626768
  var valid_21626769 = path.getOrDefault("AwsAccountId")
  valid_21626769 = validateParameter(valid_21626769, JString, required = true,
                                   default = nil)
  if valid_21626769 != nil:
    section.add "AwsAccountId", valid_21626769
  var valid_21626770 = path.getOrDefault("Namespace")
  valid_21626770 = validateParameter(valid_21626770, JString, required = true,
                                   default = nil)
  if valid_21626770 != nil:
    section.add "Namespace", valid_21626770
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626771 = header.getOrDefault("X-Amz-Date")
  valid_21626771 = validateParameter(valid_21626771, JString, required = false,
                                   default = nil)
  if valid_21626771 != nil:
    section.add "X-Amz-Date", valid_21626771
  var valid_21626772 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626772 = validateParameter(valid_21626772, JString, required = false,
                                   default = nil)
  if valid_21626772 != nil:
    section.add "X-Amz-Security-Token", valid_21626772
  var valid_21626773 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626773 = validateParameter(valid_21626773, JString, required = false,
                                   default = nil)
  if valid_21626773 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626773
  var valid_21626774 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626774 = validateParameter(valid_21626774, JString, required = false,
                                   default = nil)
  if valid_21626774 != nil:
    section.add "X-Amz-Algorithm", valid_21626774
  var valid_21626775 = header.getOrDefault("X-Amz-Signature")
  valid_21626775 = validateParameter(valid_21626775, JString, required = false,
                                   default = nil)
  if valid_21626775 != nil:
    section.add "X-Amz-Signature", valid_21626775
  var valid_21626776 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626776 = validateParameter(valid_21626776, JString, required = false,
                                   default = nil)
  if valid_21626776 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626776
  var valid_21626777 = header.getOrDefault("X-Amz-Credential")
  valid_21626777 = validateParameter(valid_21626777, JString, required = false,
                                   default = nil)
  if valid_21626777 != nil:
    section.add "X-Amz-Credential", valid_21626777
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626779: Call_UpdateIAMPolicyAssignment_21626765;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an existing IAM policy assignment. This operation updates only the optional parameter or parameters that are specified in the request.
  ## 
  let valid = call_21626779.validator(path, query, header, formData, body, _)
  let scheme = call_21626779.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626779.makeUrl(scheme.get, call_21626779.host, call_21626779.base,
                               call_21626779.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626779, uri, valid, _)

proc call*(call_21626780: Call_UpdateIAMPolicyAssignment_21626765;
          AssignmentName: string; AwsAccountId: string; body: JsonNode;
          Namespace: string): Recallable =
  ## updateIAMPolicyAssignment
  ## Updates an existing IAM policy assignment. This operation updates only the optional parameter or parameters that are specified in the request.
  ##   AssignmentName: string (required)
  ##                 : The name of the assignment. This name must be unique within an AWS account.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the IAM policy assignment.
  ##   body: JObject (required)
  ##   Namespace: string (required)
  ##            : The namespace of the assignment.
  var path_21626781 = newJObject()
  var body_21626782 = newJObject()
  add(path_21626781, "AssignmentName", newJString(AssignmentName))
  add(path_21626781, "AwsAccountId", newJString(AwsAccountId))
  if body != nil:
    body_21626782 = body
  add(path_21626781, "Namespace", newJString(Namespace))
  result = call_21626780.call(path_21626781, nil, nil, nil, body_21626782)

var updateIAMPolicyAssignment* = Call_UpdateIAMPolicyAssignment_21626765(
    name: "updateIAMPolicyAssignment", meth: HttpMethod.HttpPut,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/iam-policy-assignments/{AssignmentName}",
    validator: validate_UpdateIAMPolicyAssignment_21626766, base: "/",
    makeUrl: url_UpdateIAMPolicyAssignment_21626767,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeIAMPolicyAssignment_21626749 = ref object of OpenApiRestCall_21625435
proc url_DescribeIAMPolicyAssignment_21626751(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "Namespace" in path, "`Namespace` is a required path parameter"
  assert "AssignmentName" in path, "`AssignmentName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/namespaces/"),
               (kind: VariableSegment, value: "Namespace"),
               (kind: ConstantSegment, value: "/iam-policy-assignments/"),
               (kind: VariableSegment, value: "AssignmentName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeIAMPolicyAssignment_21626750(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Describes an existing IAM policy assignment, as specified by the assignment name.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AssignmentName: JString (required)
  ##                 : The name of the assignment. 
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account that contains the assignment that you want to describe.
  ##   Namespace: JString (required)
  ##            : The namespace that contains the assignment.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AssignmentName` field"
  var valid_21626752 = path.getOrDefault("AssignmentName")
  valid_21626752 = validateParameter(valid_21626752, JString, required = true,
                                   default = nil)
  if valid_21626752 != nil:
    section.add "AssignmentName", valid_21626752
  var valid_21626753 = path.getOrDefault("AwsAccountId")
  valid_21626753 = validateParameter(valid_21626753, JString, required = true,
                                   default = nil)
  if valid_21626753 != nil:
    section.add "AwsAccountId", valid_21626753
  var valid_21626754 = path.getOrDefault("Namespace")
  valid_21626754 = validateParameter(valid_21626754, JString, required = true,
                                   default = nil)
  if valid_21626754 != nil:
    section.add "Namespace", valid_21626754
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626755 = header.getOrDefault("X-Amz-Date")
  valid_21626755 = validateParameter(valid_21626755, JString, required = false,
                                   default = nil)
  if valid_21626755 != nil:
    section.add "X-Amz-Date", valid_21626755
  var valid_21626756 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626756 = validateParameter(valid_21626756, JString, required = false,
                                   default = nil)
  if valid_21626756 != nil:
    section.add "X-Amz-Security-Token", valid_21626756
  var valid_21626757 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626757 = validateParameter(valid_21626757, JString, required = false,
                                   default = nil)
  if valid_21626757 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626757
  var valid_21626758 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626758 = validateParameter(valid_21626758, JString, required = false,
                                   default = nil)
  if valid_21626758 != nil:
    section.add "X-Amz-Algorithm", valid_21626758
  var valid_21626759 = header.getOrDefault("X-Amz-Signature")
  valid_21626759 = validateParameter(valid_21626759, JString, required = false,
                                   default = nil)
  if valid_21626759 != nil:
    section.add "X-Amz-Signature", valid_21626759
  var valid_21626760 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626760 = validateParameter(valid_21626760, JString, required = false,
                                   default = nil)
  if valid_21626760 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626760
  var valid_21626761 = header.getOrDefault("X-Amz-Credential")
  valid_21626761 = validateParameter(valid_21626761, JString, required = false,
                                   default = nil)
  if valid_21626761 != nil:
    section.add "X-Amz-Credential", valid_21626761
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626762: Call_DescribeIAMPolicyAssignment_21626749;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes an existing IAM policy assignment, as specified by the assignment name.
  ## 
  let valid = call_21626762.validator(path, query, header, formData, body, _)
  let scheme = call_21626762.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626762.makeUrl(scheme.get, call_21626762.host, call_21626762.base,
                               call_21626762.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626762, uri, valid, _)

proc call*(call_21626763: Call_DescribeIAMPolicyAssignment_21626749;
          AssignmentName: string; AwsAccountId: string; Namespace: string): Recallable =
  ## describeIAMPolicyAssignment
  ## Describes an existing IAM policy assignment, as specified by the assignment name.
  ##   AssignmentName: string (required)
  ##                 : The name of the assignment. 
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the assignment that you want to describe.
  ##   Namespace: string (required)
  ##            : The namespace that contains the assignment.
  var path_21626764 = newJObject()
  add(path_21626764, "AssignmentName", newJString(AssignmentName))
  add(path_21626764, "AwsAccountId", newJString(AwsAccountId))
  add(path_21626764, "Namespace", newJString(Namespace))
  result = call_21626763.call(path_21626764, nil, nil, nil, nil)

var describeIAMPolicyAssignment* = Call_DescribeIAMPolicyAssignment_21626749(
    name: "describeIAMPolicyAssignment", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/iam-policy-assignments/{AssignmentName}",
    validator: validate_DescribeIAMPolicyAssignment_21626750, base: "/",
    makeUrl: url_DescribeIAMPolicyAssignment_21626751,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTemplatePermissions_21626798 = ref object of OpenApiRestCall_21625435
proc url_UpdateTemplatePermissions_21626800(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "TemplateId" in path, "`TemplateId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/templates/"),
               (kind: VariableSegment, value: "TemplateId"),
               (kind: ConstantSegment, value: "/permissions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateTemplatePermissions_21626799(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates the resource permissions for a template.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account that contains the template.
  ##   TemplateId: JString (required)
  ##             : The ID for the template.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_21626801 = path.getOrDefault("AwsAccountId")
  valid_21626801 = validateParameter(valid_21626801, JString, required = true,
                                   default = nil)
  if valid_21626801 != nil:
    section.add "AwsAccountId", valid_21626801
  var valid_21626802 = path.getOrDefault("TemplateId")
  valid_21626802 = validateParameter(valid_21626802, JString, required = true,
                                   default = nil)
  if valid_21626802 != nil:
    section.add "TemplateId", valid_21626802
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626803 = header.getOrDefault("X-Amz-Date")
  valid_21626803 = validateParameter(valid_21626803, JString, required = false,
                                   default = nil)
  if valid_21626803 != nil:
    section.add "X-Amz-Date", valid_21626803
  var valid_21626804 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626804 = validateParameter(valid_21626804, JString, required = false,
                                   default = nil)
  if valid_21626804 != nil:
    section.add "X-Amz-Security-Token", valid_21626804
  var valid_21626805 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626805 = validateParameter(valid_21626805, JString, required = false,
                                   default = nil)
  if valid_21626805 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626805
  var valid_21626806 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626806 = validateParameter(valid_21626806, JString, required = false,
                                   default = nil)
  if valid_21626806 != nil:
    section.add "X-Amz-Algorithm", valid_21626806
  var valid_21626807 = header.getOrDefault("X-Amz-Signature")
  valid_21626807 = validateParameter(valid_21626807, JString, required = false,
                                   default = nil)
  if valid_21626807 != nil:
    section.add "X-Amz-Signature", valid_21626807
  var valid_21626808 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626808 = validateParameter(valid_21626808, JString, required = false,
                                   default = nil)
  if valid_21626808 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626808
  var valid_21626809 = header.getOrDefault("X-Amz-Credential")
  valid_21626809 = validateParameter(valid_21626809, JString, required = false,
                                   default = nil)
  if valid_21626809 != nil:
    section.add "X-Amz-Credential", valid_21626809
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626811: Call_UpdateTemplatePermissions_21626798;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the resource permissions for a template.
  ## 
  let valid = call_21626811.validator(path, query, header, formData, body, _)
  let scheme = call_21626811.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626811.makeUrl(scheme.get, call_21626811.host, call_21626811.base,
                               call_21626811.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626811, uri, valid, _)

proc call*(call_21626812: Call_UpdateTemplatePermissions_21626798;
          AwsAccountId: string; TemplateId: string; body: JsonNode): Recallable =
  ## updateTemplatePermissions
  ## Updates the resource permissions for a template.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the template.
  ##   TemplateId: string (required)
  ##             : The ID for the template.
  ##   body: JObject (required)
  var path_21626813 = newJObject()
  var body_21626814 = newJObject()
  add(path_21626813, "AwsAccountId", newJString(AwsAccountId))
  add(path_21626813, "TemplateId", newJString(TemplateId))
  if body != nil:
    body_21626814 = body
  result = call_21626812.call(path_21626813, nil, nil, nil, body_21626814)

var updateTemplatePermissions* = Call_UpdateTemplatePermissions_21626798(
    name: "updateTemplatePermissions", meth: HttpMethod.HttpPut,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates/{TemplateId}/permissions",
    validator: validate_UpdateTemplatePermissions_21626799, base: "/",
    makeUrl: url_UpdateTemplatePermissions_21626800,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTemplatePermissions_21626783 = ref object of OpenApiRestCall_21625435
proc url_DescribeTemplatePermissions_21626785(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "TemplateId" in path, "`TemplateId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/templates/"),
               (kind: VariableSegment, value: "TemplateId"),
               (kind: ConstantSegment, value: "/permissions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeTemplatePermissions_21626784(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Describes read and write permissions on a template.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account that contains the template that you're describing.
  ##   TemplateId: JString (required)
  ##             : The ID for the template.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_21626786 = path.getOrDefault("AwsAccountId")
  valid_21626786 = validateParameter(valid_21626786, JString, required = true,
                                   default = nil)
  if valid_21626786 != nil:
    section.add "AwsAccountId", valid_21626786
  var valid_21626787 = path.getOrDefault("TemplateId")
  valid_21626787 = validateParameter(valid_21626787, JString, required = true,
                                   default = nil)
  if valid_21626787 != nil:
    section.add "TemplateId", valid_21626787
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626788 = header.getOrDefault("X-Amz-Date")
  valid_21626788 = validateParameter(valid_21626788, JString, required = false,
                                   default = nil)
  if valid_21626788 != nil:
    section.add "X-Amz-Date", valid_21626788
  var valid_21626789 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626789 = validateParameter(valid_21626789, JString, required = false,
                                   default = nil)
  if valid_21626789 != nil:
    section.add "X-Amz-Security-Token", valid_21626789
  var valid_21626790 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626790 = validateParameter(valid_21626790, JString, required = false,
                                   default = nil)
  if valid_21626790 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626790
  var valid_21626791 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626791 = validateParameter(valid_21626791, JString, required = false,
                                   default = nil)
  if valid_21626791 != nil:
    section.add "X-Amz-Algorithm", valid_21626791
  var valid_21626792 = header.getOrDefault("X-Amz-Signature")
  valid_21626792 = validateParameter(valid_21626792, JString, required = false,
                                   default = nil)
  if valid_21626792 != nil:
    section.add "X-Amz-Signature", valid_21626792
  var valid_21626793 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626793 = validateParameter(valid_21626793, JString, required = false,
                                   default = nil)
  if valid_21626793 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626793
  var valid_21626794 = header.getOrDefault("X-Amz-Credential")
  valid_21626794 = validateParameter(valid_21626794, JString, required = false,
                                   default = nil)
  if valid_21626794 != nil:
    section.add "X-Amz-Credential", valid_21626794
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626795: Call_DescribeTemplatePermissions_21626783;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes read and write permissions on a template.
  ## 
  let valid = call_21626795.validator(path, query, header, formData, body, _)
  let scheme = call_21626795.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626795.makeUrl(scheme.get, call_21626795.host, call_21626795.base,
                               call_21626795.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626795, uri, valid, _)

proc call*(call_21626796: Call_DescribeTemplatePermissions_21626783;
          AwsAccountId: string; TemplateId: string): Recallable =
  ## describeTemplatePermissions
  ## Describes read and write permissions on a template.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the template that you're describing.
  ##   TemplateId: string (required)
  ##             : The ID for the template.
  var path_21626797 = newJObject()
  add(path_21626797, "AwsAccountId", newJString(AwsAccountId))
  add(path_21626797, "TemplateId", newJString(TemplateId))
  result = call_21626796.call(path_21626797, nil, nil, nil, nil)

var describeTemplatePermissions* = Call_DescribeTemplatePermissions_21626783(
    name: "describeTemplatePermissions", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates/{TemplateId}/permissions",
    validator: validate_DescribeTemplatePermissions_21626784, base: "/",
    makeUrl: url_DescribeTemplatePermissions_21626785,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDashboardEmbedUrl_21626815 = ref object of OpenApiRestCall_21625435
proc url_GetDashboardEmbedUrl_21626817(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "DashboardId" in path, "`DashboardId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/dashboards/"),
               (kind: VariableSegment, value: "DashboardId"),
               (kind: ConstantSegment, value: "/embed-url#creds-type")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDashboardEmbedUrl_21626816(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Generates a server-side embeddable URL and authorization code. For this process to work properly, first configure the dashboards and user permissions. For more information, see <a href="https://docs.aws.amazon.com/quicksight/latest/user/embedding-dashboards.html">Embedding Amazon QuickSight Dashboards</a> in the <i>Amazon QuickSight User Guide</i> or <a href="https://docs.aws.amazon.com/quicksight/latest/APIReference/qs-dev-embedded-dashboards.html">Embedding Amazon QuickSight Dashboards</a> in the <i>Amazon QuickSight API Reference</i>.</p> <p>Currently, you can use <code>GetDashboardEmbedURL</code> only from the server, not from the user’s browser.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that contains the dashboard that you're embedding.
  ##   DashboardId: JString (required)
  ##              : The ID for the dashboard, also added to the IAM policy.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_21626818 = path.getOrDefault("AwsAccountId")
  valid_21626818 = validateParameter(valid_21626818, JString, required = true,
                                   default = nil)
  if valid_21626818 != nil:
    section.add "AwsAccountId", valid_21626818
  var valid_21626819 = path.getOrDefault("DashboardId")
  valid_21626819 = validateParameter(valid_21626819, JString, required = true,
                                   default = nil)
  if valid_21626819 != nil:
    section.add "DashboardId", valid_21626819
  result.add "path", section
  ## parameters in `query` object:
  ##   session-lifetime: JInt
  ##                   : How many minutes the session is valid. The session lifetime must be 15-600 minutes.
  ##   reset-disabled: JBool
  ##                 : Remove the reset button on the embedded dashboard. The default is FALSE, which enables the reset button.
  ##   user-arn: JString
  ##           : <p>The Amazon QuickSight user's Amazon Resource Name (ARN), for use with <code>QUICKSIGHT</code> identity type. You can use this for any Amazon QuickSight users in your account (readers, authors, or admins) authenticated as one of the following:</p> <ul> <li> <p>Active Directory (AD) users or group members</p> </li> <li> <p>Invited nonfederated users</p> </li> <li> <p>IAM users and IAM role-based sessions authenticated through Federated Single Sign-On using SAML, OpenID Connect, or IAM federation.</p> </li> </ul>
  ##   undo-redo-disabled: JBool
  ##                     : Remove the undo/redo button on the embedded dashboard. The default is FALSE, which enables the undo/redo button.
  ##   creds-type: JString (required)
  ##             : The authentication method that the user uses to sign in.
  section = newJObject()
  var valid_21626820 = query.getOrDefault("session-lifetime")
  valid_21626820 = validateParameter(valid_21626820, JInt, required = false,
                                   default = nil)
  if valid_21626820 != nil:
    section.add "session-lifetime", valid_21626820
  var valid_21626821 = query.getOrDefault("reset-disabled")
  valid_21626821 = validateParameter(valid_21626821, JBool, required = false,
                                   default = nil)
  if valid_21626821 != nil:
    section.add "reset-disabled", valid_21626821
  var valid_21626822 = query.getOrDefault("user-arn")
  valid_21626822 = validateParameter(valid_21626822, JString, required = false,
                                   default = nil)
  if valid_21626822 != nil:
    section.add "user-arn", valid_21626822
  var valid_21626823 = query.getOrDefault("undo-redo-disabled")
  valid_21626823 = validateParameter(valid_21626823, JBool, required = false,
                                   default = nil)
  if valid_21626823 != nil:
    section.add "undo-redo-disabled", valid_21626823
  var valid_21626838 = query.getOrDefault("creds-type")
  valid_21626838 = validateParameter(valid_21626838, JString, required = true,
                                   default = newJString("IAM"))
  if valid_21626838 != nil:
    section.add "creds-type", valid_21626838
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626839 = header.getOrDefault("X-Amz-Date")
  valid_21626839 = validateParameter(valid_21626839, JString, required = false,
                                   default = nil)
  if valid_21626839 != nil:
    section.add "X-Amz-Date", valid_21626839
  var valid_21626840 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626840 = validateParameter(valid_21626840, JString, required = false,
                                   default = nil)
  if valid_21626840 != nil:
    section.add "X-Amz-Security-Token", valid_21626840
  var valid_21626841 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626841 = validateParameter(valid_21626841, JString, required = false,
                                   default = nil)
  if valid_21626841 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626841
  var valid_21626842 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626842 = validateParameter(valid_21626842, JString, required = false,
                                   default = nil)
  if valid_21626842 != nil:
    section.add "X-Amz-Algorithm", valid_21626842
  var valid_21626843 = header.getOrDefault("X-Amz-Signature")
  valid_21626843 = validateParameter(valid_21626843, JString, required = false,
                                   default = nil)
  if valid_21626843 != nil:
    section.add "X-Amz-Signature", valid_21626843
  var valid_21626844 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626844 = validateParameter(valid_21626844, JString, required = false,
                                   default = nil)
  if valid_21626844 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626844
  var valid_21626845 = header.getOrDefault("X-Amz-Credential")
  valid_21626845 = validateParameter(valid_21626845, JString, required = false,
                                   default = nil)
  if valid_21626845 != nil:
    section.add "X-Amz-Credential", valid_21626845
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626846: Call_GetDashboardEmbedUrl_21626815; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Generates a server-side embeddable URL and authorization code. For this process to work properly, first configure the dashboards and user permissions. For more information, see <a href="https://docs.aws.amazon.com/quicksight/latest/user/embedding-dashboards.html">Embedding Amazon QuickSight Dashboards</a> in the <i>Amazon QuickSight User Guide</i> or <a href="https://docs.aws.amazon.com/quicksight/latest/APIReference/qs-dev-embedded-dashboards.html">Embedding Amazon QuickSight Dashboards</a> in the <i>Amazon QuickSight API Reference</i>.</p> <p>Currently, you can use <code>GetDashboardEmbedURL</code> only from the server, not from the user’s browser.</p>
  ## 
  let valid = call_21626846.validator(path, query, header, formData, body, _)
  let scheme = call_21626846.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626846.makeUrl(scheme.get, call_21626846.host, call_21626846.base,
                               call_21626846.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626846, uri, valid, _)

proc call*(call_21626847: Call_GetDashboardEmbedUrl_21626815; AwsAccountId: string;
          DashboardId: string; sessionLifetime: int = 0; resetDisabled: bool = false;
          userArn: string = ""; undoRedoDisabled: bool = false;
          credsType: string = "IAM"): Recallable =
  ## getDashboardEmbedUrl
  ## <p>Generates a server-side embeddable URL and authorization code. For this process to work properly, first configure the dashboards and user permissions. For more information, see <a href="https://docs.aws.amazon.com/quicksight/latest/user/embedding-dashboards.html">Embedding Amazon QuickSight Dashboards</a> in the <i>Amazon QuickSight User Guide</i> or <a href="https://docs.aws.amazon.com/quicksight/latest/APIReference/qs-dev-embedded-dashboards.html">Embedding Amazon QuickSight Dashboards</a> in the <i>Amazon QuickSight API Reference</i>.</p> <p>Currently, you can use <code>GetDashboardEmbedURL</code> only from the server, not from the user’s browser.</p>
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that contains the dashboard that you're embedding.
  ##   sessionLifetime: int
  ##                  : How many minutes the session is valid. The session lifetime must be 15-600 minutes.
  ##   resetDisabled: bool
  ##                : Remove the reset button on the embedded dashboard. The default is FALSE, which enables the reset button.
  ##   userArn: string
  ##          : <p>The Amazon QuickSight user's Amazon Resource Name (ARN), for use with <code>QUICKSIGHT</code> identity type. You can use this for any Amazon QuickSight users in your account (readers, authors, or admins) authenticated as one of the following:</p> <ul> <li> <p>Active Directory (AD) users or group members</p> </li> <li> <p>Invited nonfederated users</p> </li> <li> <p>IAM users and IAM role-based sessions authenticated through Federated Single Sign-On using SAML, OpenID Connect, or IAM federation.</p> </li> </ul>
  ##   DashboardId: string (required)
  ##              : The ID for the dashboard, also added to the IAM policy.
  ##   undoRedoDisabled: bool
  ##                   : Remove the undo/redo button on the embedded dashboard. The default is FALSE, which enables the undo/redo button.
  ##   credsType: string (required)
  ##            : The authentication method that the user uses to sign in.
  var path_21626848 = newJObject()
  var query_21626849 = newJObject()
  add(path_21626848, "AwsAccountId", newJString(AwsAccountId))
  add(query_21626849, "session-lifetime", newJInt(sessionLifetime))
  add(query_21626849, "reset-disabled", newJBool(resetDisabled))
  add(query_21626849, "user-arn", newJString(userArn))
  add(path_21626848, "DashboardId", newJString(DashboardId))
  add(query_21626849, "undo-redo-disabled", newJBool(undoRedoDisabled))
  add(query_21626849, "creds-type", newJString(credsType))
  result = call_21626847.call(path_21626848, query_21626849, nil, nil, nil)

var getDashboardEmbedUrl* = Call_GetDashboardEmbedUrl_21626815(
    name: "getDashboardEmbedUrl", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}/embed-url#creds-type",
    validator: validate_GetDashboardEmbedUrl_21626816, base: "/",
    makeUrl: url_GetDashboardEmbedUrl_21626817,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDashboardVersions_21626851 = ref object of OpenApiRestCall_21625435
proc url_ListDashboardVersions_21626853(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "DashboardId" in path, "`DashboardId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/dashboards/"),
               (kind: VariableSegment, value: "DashboardId"),
               (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListDashboardVersions_21626852(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists all the versions of the dashboards in the QuickSight subscription.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account that contains the dashboard that you're listing versions for.
  ##   DashboardId: JString (required)
  ##              : The ID for the dashboard.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_21626854 = path.getOrDefault("AwsAccountId")
  valid_21626854 = validateParameter(valid_21626854, JString, required = true,
                                   default = nil)
  if valid_21626854 != nil:
    section.add "AwsAccountId", valid_21626854
  var valid_21626855 = path.getOrDefault("DashboardId")
  valid_21626855 = validateParameter(valid_21626855, JString, required = true,
                                   default = nil)
  if valid_21626855 != nil:
    section.add "DashboardId", valid_21626855
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   max-results: JInt
  ##              : The maximum number of results to be returned per request.
  ##   next-token: JString
  ##             : The token for the next set of results, or null if there are no more results.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626856 = query.getOrDefault("NextToken")
  valid_21626856 = validateParameter(valid_21626856, JString, required = false,
                                   default = nil)
  if valid_21626856 != nil:
    section.add "NextToken", valid_21626856
  var valid_21626857 = query.getOrDefault("max-results")
  valid_21626857 = validateParameter(valid_21626857, JInt, required = false,
                                   default = nil)
  if valid_21626857 != nil:
    section.add "max-results", valid_21626857
  var valid_21626858 = query.getOrDefault("next-token")
  valid_21626858 = validateParameter(valid_21626858, JString, required = false,
                                   default = nil)
  if valid_21626858 != nil:
    section.add "next-token", valid_21626858
  var valid_21626859 = query.getOrDefault("MaxResults")
  valid_21626859 = validateParameter(valid_21626859, JString, required = false,
                                   default = nil)
  if valid_21626859 != nil:
    section.add "MaxResults", valid_21626859
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626860 = header.getOrDefault("X-Amz-Date")
  valid_21626860 = validateParameter(valid_21626860, JString, required = false,
                                   default = nil)
  if valid_21626860 != nil:
    section.add "X-Amz-Date", valid_21626860
  var valid_21626861 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626861 = validateParameter(valid_21626861, JString, required = false,
                                   default = nil)
  if valid_21626861 != nil:
    section.add "X-Amz-Security-Token", valid_21626861
  var valid_21626862 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626862 = validateParameter(valid_21626862, JString, required = false,
                                   default = nil)
  if valid_21626862 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626862
  var valid_21626863 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626863 = validateParameter(valid_21626863, JString, required = false,
                                   default = nil)
  if valid_21626863 != nil:
    section.add "X-Amz-Algorithm", valid_21626863
  var valid_21626864 = header.getOrDefault("X-Amz-Signature")
  valid_21626864 = validateParameter(valid_21626864, JString, required = false,
                                   default = nil)
  if valid_21626864 != nil:
    section.add "X-Amz-Signature", valid_21626864
  var valid_21626865 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626865 = validateParameter(valid_21626865, JString, required = false,
                                   default = nil)
  if valid_21626865 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626865
  var valid_21626866 = header.getOrDefault("X-Amz-Credential")
  valid_21626866 = validateParameter(valid_21626866, JString, required = false,
                                   default = nil)
  if valid_21626866 != nil:
    section.add "X-Amz-Credential", valid_21626866
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626867: Call_ListDashboardVersions_21626851;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all the versions of the dashboards in the QuickSight subscription.
  ## 
  let valid = call_21626867.validator(path, query, header, formData, body, _)
  let scheme = call_21626867.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626867.makeUrl(scheme.get, call_21626867.host, call_21626867.base,
                               call_21626867.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626867, uri, valid, _)

proc call*(call_21626868: Call_ListDashboardVersions_21626851;
          AwsAccountId: string; DashboardId: string; NextToken: string = "";
          maxResults: int = 0; nextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listDashboardVersions
  ## Lists all the versions of the dashboards in the QuickSight subscription.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the dashboard that you're listing versions for.
  ##   DashboardId: string (required)
  ##              : The ID for the dashboard.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results to be returned per request.
  ##   nextToken: string
  ##            : The token for the next set of results, or null if there are no more results.
  ##   MaxResults: string
  ##             : Pagination limit
  var path_21626869 = newJObject()
  var query_21626870 = newJObject()
  add(path_21626869, "AwsAccountId", newJString(AwsAccountId))
  add(path_21626869, "DashboardId", newJString(DashboardId))
  add(query_21626870, "NextToken", newJString(NextToken))
  add(query_21626870, "max-results", newJInt(maxResults))
  add(query_21626870, "next-token", newJString(nextToken))
  add(query_21626870, "MaxResults", newJString(MaxResults))
  result = call_21626868.call(path_21626869, query_21626870, nil, nil, nil)

var listDashboardVersions* = Call_ListDashboardVersions_21626851(
    name: "listDashboardVersions", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}/versions",
    validator: validate_ListDashboardVersions_21626852, base: "/",
    makeUrl: url_ListDashboardVersions_21626853,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDashboards_21626871 = ref object of OpenApiRestCall_21625435
proc url_ListDashboards_21626873(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/dashboards")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListDashboards_21626872(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists dashboards in an AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account that contains the dashboards that you're listing.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_21626874 = path.getOrDefault("AwsAccountId")
  valid_21626874 = validateParameter(valid_21626874, JString, required = true,
                                   default = nil)
  if valid_21626874 != nil:
    section.add "AwsAccountId", valid_21626874
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   max-results: JInt
  ##              : The maximum number of results to be returned per request.
  ##   next-token: JString
  ##             : The token for the next set of results, or null if there are no more results.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626875 = query.getOrDefault("NextToken")
  valid_21626875 = validateParameter(valid_21626875, JString, required = false,
                                   default = nil)
  if valid_21626875 != nil:
    section.add "NextToken", valid_21626875
  var valid_21626876 = query.getOrDefault("max-results")
  valid_21626876 = validateParameter(valid_21626876, JInt, required = false,
                                   default = nil)
  if valid_21626876 != nil:
    section.add "max-results", valid_21626876
  var valid_21626877 = query.getOrDefault("next-token")
  valid_21626877 = validateParameter(valid_21626877, JString, required = false,
                                   default = nil)
  if valid_21626877 != nil:
    section.add "next-token", valid_21626877
  var valid_21626878 = query.getOrDefault("MaxResults")
  valid_21626878 = validateParameter(valid_21626878, JString, required = false,
                                   default = nil)
  if valid_21626878 != nil:
    section.add "MaxResults", valid_21626878
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626879 = header.getOrDefault("X-Amz-Date")
  valid_21626879 = validateParameter(valid_21626879, JString, required = false,
                                   default = nil)
  if valid_21626879 != nil:
    section.add "X-Amz-Date", valid_21626879
  var valid_21626880 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626880 = validateParameter(valid_21626880, JString, required = false,
                                   default = nil)
  if valid_21626880 != nil:
    section.add "X-Amz-Security-Token", valid_21626880
  var valid_21626881 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626881 = validateParameter(valid_21626881, JString, required = false,
                                   default = nil)
  if valid_21626881 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626881
  var valid_21626882 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626882 = validateParameter(valid_21626882, JString, required = false,
                                   default = nil)
  if valid_21626882 != nil:
    section.add "X-Amz-Algorithm", valid_21626882
  var valid_21626883 = header.getOrDefault("X-Amz-Signature")
  valid_21626883 = validateParameter(valid_21626883, JString, required = false,
                                   default = nil)
  if valid_21626883 != nil:
    section.add "X-Amz-Signature", valid_21626883
  var valid_21626884 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626884 = validateParameter(valid_21626884, JString, required = false,
                                   default = nil)
  if valid_21626884 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626884
  var valid_21626885 = header.getOrDefault("X-Amz-Credential")
  valid_21626885 = validateParameter(valid_21626885, JString, required = false,
                                   default = nil)
  if valid_21626885 != nil:
    section.add "X-Amz-Credential", valid_21626885
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626886: Call_ListDashboards_21626871; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists dashboards in an AWS account.
  ## 
  let valid = call_21626886.validator(path, query, header, formData, body, _)
  let scheme = call_21626886.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626886.makeUrl(scheme.get, call_21626886.host, call_21626886.base,
                               call_21626886.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626886, uri, valid, _)

proc call*(call_21626887: Call_ListDashboards_21626871; AwsAccountId: string;
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listDashboards
  ## Lists dashboards in an AWS account.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the dashboards that you're listing.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results to be returned per request.
  ##   nextToken: string
  ##            : The token for the next set of results, or null if there are no more results.
  ##   MaxResults: string
  ##             : Pagination limit
  var path_21626888 = newJObject()
  var query_21626889 = newJObject()
  add(path_21626888, "AwsAccountId", newJString(AwsAccountId))
  add(query_21626889, "NextToken", newJString(NextToken))
  add(query_21626889, "max-results", newJInt(maxResults))
  add(query_21626889, "next-token", newJString(nextToken))
  add(query_21626889, "MaxResults", newJString(MaxResults))
  result = call_21626887.call(path_21626888, query_21626889, nil, nil, nil)

var listDashboards* = Call_ListDashboards_21626871(name: "listDashboards",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/dashboards",
    validator: validate_ListDashboards_21626872, base: "/",
    makeUrl: url_ListDashboards_21626873, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroupMemberships_21626890 = ref object of OpenApiRestCall_21625435
proc url_ListGroupMemberships_21626892(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "Namespace" in path, "`Namespace` is a required path parameter"
  assert "GroupName" in path, "`GroupName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/namespaces/"),
               (kind: VariableSegment, value: "Namespace"),
               (kind: ConstantSegment, value: "/groups/"),
               (kind: VariableSegment, value: "GroupName"),
               (kind: ConstantSegment, value: "/members")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListGroupMemberships_21626891(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists member users in a group.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupName: JString (required)
  ##            : The name of the group that you want to see a membership list of.
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupName` field"
  var valid_21626893 = path.getOrDefault("GroupName")
  valid_21626893 = validateParameter(valid_21626893, JString, required = true,
                                   default = nil)
  if valid_21626893 != nil:
    section.add "GroupName", valid_21626893
  var valid_21626894 = path.getOrDefault("AwsAccountId")
  valid_21626894 = validateParameter(valid_21626894, JString, required = true,
                                   default = nil)
  if valid_21626894 != nil:
    section.add "AwsAccountId", valid_21626894
  var valid_21626895 = path.getOrDefault("Namespace")
  valid_21626895 = validateParameter(valid_21626895, JString, required = true,
                                   default = nil)
  if valid_21626895 != nil:
    section.add "Namespace", valid_21626895
  result.add "path", section
  ## parameters in `query` object:
  ##   max-results: JInt
  ##              : The maximum number of results to return from this request.
  ##   next-token: JString
  ##             : A pagination token that can be used in a subsequent request.
  section = newJObject()
  var valid_21626896 = query.getOrDefault("max-results")
  valid_21626896 = validateParameter(valid_21626896, JInt, required = false,
                                   default = nil)
  if valid_21626896 != nil:
    section.add "max-results", valid_21626896
  var valid_21626897 = query.getOrDefault("next-token")
  valid_21626897 = validateParameter(valid_21626897, JString, required = false,
                                   default = nil)
  if valid_21626897 != nil:
    section.add "next-token", valid_21626897
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626898 = header.getOrDefault("X-Amz-Date")
  valid_21626898 = validateParameter(valid_21626898, JString, required = false,
                                   default = nil)
  if valid_21626898 != nil:
    section.add "X-Amz-Date", valid_21626898
  var valid_21626899 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626899 = validateParameter(valid_21626899, JString, required = false,
                                   default = nil)
  if valid_21626899 != nil:
    section.add "X-Amz-Security-Token", valid_21626899
  var valid_21626900 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626900 = validateParameter(valid_21626900, JString, required = false,
                                   default = nil)
  if valid_21626900 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626900
  var valid_21626901 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626901 = validateParameter(valid_21626901, JString, required = false,
                                   default = nil)
  if valid_21626901 != nil:
    section.add "X-Amz-Algorithm", valid_21626901
  var valid_21626902 = header.getOrDefault("X-Amz-Signature")
  valid_21626902 = validateParameter(valid_21626902, JString, required = false,
                                   default = nil)
  if valid_21626902 != nil:
    section.add "X-Amz-Signature", valid_21626902
  var valid_21626903 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626903 = validateParameter(valid_21626903, JString, required = false,
                                   default = nil)
  if valid_21626903 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626903
  var valid_21626904 = header.getOrDefault("X-Amz-Credential")
  valid_21626904 = validateParameter(valid_21626904, JString, required = false,
                                   default = nil)
  if valid_21626904 != nil:
    section.add "X-Amz-Credential", valid_21626904
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626905: Call_ListGroupMemberships_21626890; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists member users in a group.
  ## 
  let valid = call_21626905.validator(path, query, header, formData, body, _)
  let scheme = call_21626905.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626905.makeUrl(scheme.get, call_21626905.host, call_21626905.base,
                               call_21626905.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626905, uri, valid, _)

proc call*(call_21626906: Call_ListGroupMemberships_21626890; GroupName: string;
          AwsAccountId: string; Namespace: string; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listGroupMemberships
  ## Lists member users in a group.
  ##   GroupName: string (required)
  ##            : The name of the group that you want to see a membership list of.
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   maxResults: int
  ##             : The maximum number of results to return from this request.
  ##   nextToken: string
  ##            : A pagination token that can be used in a subsequent request.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  var path_21626907 = newJObject()
  var query_21626908 = newJObject()
  add(path_21626907, "GroupName", newJString(GroupName))
  add(path_21626907, "AwsAccountId", newJString(AwsAccountId))
  add(query_21626908, "max-results", newJInt(maxResults))
  add(query_21626908, "next-token", newJString(nextToken))
  add(path_21626907, "Namespace", newJString(Namespace))
  result = call_21626906.call(path_21626907, query_21626908, nil, nil, nil)

var listGroupMemberships* = Call_ListGroupMemberships_21626890(
    name: "listGroupMemberships", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}/members",
    validator: validate_ListGroupMemberships_21626891, base: "/",
    makeUrl: url_ListGroupMemberships_21626892,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIAMPolicyAssignments_21626909 = ref object of OpenApiRestCall_21625435
proc url_ListIAMPolicyAssignments_21626911(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "Namespace" in path, "`Namespace` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/namespaces/"),
               (kind: VariableSegment, value: "Namespace"),
               (kind: ConstantSegment, value: "/iam-policy-assignments")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListIAMPolicyAssignments_21626910(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists IAM policy assignments in the current Amazon QuickSight account.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account that contains these IAM policy assignments.
  ##   Namespace: JString (required)
  ##            : The namespace for the assignments.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_21626912 = path.getOrDefault("AwsAccountId")
  valid_21626912 = validateParameter(valid_21626912, JString, required = true,
                                   default = nil)
  if valid_21626912 != nil:
    section.add "AwsAccountId", valid_21626912
  var valid_21626913 = path.getOrDefault("Namespace")
  valid_21626913 = validateParameter(valid_21626913, JString, required = true,
                                   default = nil)
  if valid_21626913 != nil:
    section.add "Namespace", valid_21626913
  result.add "path", section
  ## parameters in `query` object:
  ##   max-results: JInt
  ##              : The maximum number of results to be returned per request.
  ##   next-token: JString
  ##             : The token for the next set of results, or null if there are no more results.
  section = newJObject()
  var valid_21626914 = query.getOrDefault("max-results")
  valid_21626914 = validateParameter(valid_21626914, JInt, required = false,
                                   default = nil)
  if valid_21626914 != nil:
    section.add "max-results", valid_21626914
  var valid_21626915 = query.getOrDefault("next-token")
  valid_21626915 = validateParameter(valid_21626915, JString, required = false,
                                   default = nil)
  if valid_21626915 != nil:
    section.add "next-token", valid_21626915
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626916 = header.getOrDefault("X-Amz-Date")
  valid_21626916 = validateParameter(valid_21626916, JString, required = false,
                                   default = nil)
  if valid_21626916 != nil:
    section.add "X-Amz-Date", valid_21626916
  var valid_21626917 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626917 = validateParameter(valid_21626917, JString, required = false,
                                   default = nil)
  if valid_21626917 != nil:
    section.add "X-Amz-Security-Token", valid_21626917
  var valid_21626918 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626918 = validateParameter(valid_21626918, JString, required = false,
                                   default = nil)
  if valid_21626918 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626918
  var valid_21626919 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626919 = validateParameter(valid_21626919, JString, required = false,
                                   default = nil)
  if valid_21626919 != nil:
    section.add "X-Amz-Algorithm", valid_21626919
  var valid_21626920 = header.getOrDefault("X-Amz-Signature")
  valid_21626920 = validateParameter(valid_21626920, JString, required = false,
                                   default = nil)
  if valid_21626920 != nil:
    section.add "X-Amz-Signature", valid_21626920
  var valid_21626921 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626921 = validateParameter(valid_21626921, JString, required = false,
                                   default = nil)
  if valid_21626921 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626921
  var valid_21626922 = header.getOrDefault("X-Amz-Credential")
  valid_21626922 = validateParameter(valid_21626922, JString, required = false,
                                   default = nil)
  if valid_21626922 != nil:
    section.add "X-Amz-Credential", valid_21626922
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626924: Call_ListIAMPolicyAssignments_21626909;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists IAM policy assignments in the current Amazon QuickSight account.
  ## 
  let valid = call_21626924.validator(path, query, header, formData, body, _)
  let scheme = call_21626924.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626924.makeUrl(scheme.get, call_21626924.host, call_21626924.base,
                               call_21626924.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626924, uri, valid, _)

proc call*(call_21626925: Call_ListIAMPolicyAssignments_21626909;
          AwsAccountId: string; body: JsonNode; Namespace: string;
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listIAMPolicyAssignments
  ## Lists IAM policy assignments in the current Amazon QuickSight account.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains these IAM policy assignments.
  ##   maxResults: int
  ##             : The maximum number of results to be returned per request.
  ##   body: JObject (required)
  ##   nextToken: string
  ##            : The token for the next set of results, or null if there are no more results.
  ##   Namespace: string (required)
  ##            : The namespace for the assignments.
  var path_21626926 = newJObject()
  var query_21626927 = newJObject()
  var body_21626928 = newJObject()
  add(path_21626926, "AwsAccountId", newJString(AwsAccountId))
  add(query_21626927, "max-results", newJInt(maxResults))
  if body != nil:
    body_21626928 = body
  add(query_21626927, "next-token", newJString(nextToken))
  add(path_21626926, "Namespace", newJString(Namespace))
  result = call_21626925.call(path_21626926, query_21626927, nil, nil, body_21626928)

var listIAMPolicyAssignments* = Call_ListIAMPolicyAssignments_21626909(
    name: "listIAMPolicyAssignments", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/iam-policy-assignments",
    validator: validate_ListIAMPolicyAssignments_21626910, base: "/",
    makeUrl: url_ListIAMPolicyAssignments_21626911,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIAMPolicyAssignmentsForUser_21626929 = ref object of OpenApiRestCall_21625435
proc url_ListIAMPolicyAssignmentsForUser_21626931(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "Namespace" in path, "`Namespace` is a required path parameter"
  assert "UserName" in path, "`UserName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/namespaces/"),
               (kind: VariableSegment, value: "Namespace"),
               (kind: ConstantSegment, value: "/users/"),
               (kind: VariableSegment, value: "UserName"),
               (kind: ConstantSegment, value: "/iam-policy-assignments")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListIAMPolicyAssignmentsForUser_21626930(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Lists all the IAM policy assignments, including the Amazon Resource Names (ARNs) for the IAM policies assigned to the specified user and group or groups that the user belongs to.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account that contains the assignments.
  ##   UserName: JString (required)
  ##           : The name of the user.
  ##   Namespace: JString (required)
  ##            : The namespace of the assignment.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_21626932 = path.getOrDefault("AwsAccountId")
  valid_21626932 = validateParameter(valid_21626932, JString, required = true,
                                   default = nil)
  if valid_21626932 != nil:
    section.add "AwsAccountId", valid_21626932
  var valid_21626933 = path.getOrDefault("UserName")
  valid_21626933 = validateParameter(valid_21626933, JString, required = true,
                                   default = nil)
  if valid_21626933 != nil:
    section.add "UserName", valid_21626933
  var valid_21626934 = path.getOrDefault("Namespace")
  valid_21626934 = validateParameter(valid_21626934, JString, required = true,
                                   default = nil)
  if valid_21626934 != nil:
    section.add "Namespace", valid_21626934
  result.add "path", section
  ## parameters in `query` object:
  ##   max-results: JInt
  ##              : The maximum number of results to be returned per request.
  ##   next-token: JString
  ##             : The token for the next set of results, or null if there are no more results.
  section = newJObject()
  var valid_21626935 = query.getOrDefault("max-results")
  valid_21626935 = validateParameter(valid_21626935, JInt, required = false,
                                   default = nil)
  if valid_21626935 != nil:
    section.add "max-results", valid_21626935
  var valid_21626936 = query.getOrDefault("next-token")
  valid_21626936 = validateParameter(valid_21626936, JString, required = false,
                                   default = nil)
  if valid_21626936 != nil:
    section.add "next-token", valid_21626936
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626937 = header.getOrDefault("X-Amz-Date")
  valid_21626937 = validateParameter(valid_21626937, JString, required = false,
                                   default = nil)
  if valid_21626937 != nil:
    section.add "X-Amz-Date", valid_21626937
  var valid_21626938 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626938 = validateParameter(valid_21626938, JString, required = false,
                                   default = nil)
  if valid_21626938 != nil:
    section.add "X-Amz-Security-Token", valid_21626938
  var valid_21626939 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626939 = validateParameter(valid_21626939, JString, required = false,
                                   default = nil)
  if valid_21626939 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626939
  var valid_21626940 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626940 = validateParameter(valid_21626940, JString, required = false,
                                   default = nil)
  if valid_21626940 != nil:
    section.add "X-Amz-Algorithm", valid_21626940
  var valid_21626941 = header.getOrDefault("X-Amz-Signature")
  valid_21626941 = validateParameter(valid_21626941, JString, required = false,
                                   default = nil)
  if valid_21626941 != nil:
    section.add "X-Amz-Signature", valid_21626941
  var valid_21626942 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626942 = validateParameter(valid_21626942, JString, required = false,
                                   default = nil)
  if valid_21626942 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626942
  var valid_21626943 = header.getOrDefault("X-Amz-Credential")
  valid_21626943 = validateParameter(valid_21626943, JString, required = false,
                                   default = nil)
  if valid_21626943 != nil:
    section.add "X-Amz-Credential", valid_21626943
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626944: Call_ListIAMPolicyAssignmentsForUser_21626929;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all the IAM policy assignments, including the Amazon Resource Names (ARNs) for the IAM policies assigned to the specified user and group or groups that the user belongs to.
  ## 
  let valid = call_21626944.validator(path, query, header, formData, body, _)
  let scheme = call_21626944.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626944.makeUrl(scheme.get, call_21626944.host, call_21626944.base,
                               call_21626944.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626944, uri, valid, _)

proc call*(call_21626945: Call_ListIAMPolicyAssignmentsForUser_21626929;
          AwsAccountId: string; UserName: string; Namespace: string;
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listIAMPolicyAssignmentsForUser
  ## Lists all the IAM policy assignments, including the Amazon Resource Names (ARNs) for the IAM policies assigned to the specified user and group or groups that the user belongs to.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the assignments.
  ##   maxResults: int
  ##             : The maximum number of results to be returned per request.
  ##   nextToken: string
  ##            : The token for the next set of results, or null if there are no more results.
  ##   UserName: string (required)
  ##           : The name of the user.
  ##   Namespace: string (required)
  ##            : The namespace of the assignment.
  var path_21626946 = newJObject()
  var query_21626947 = newJObject()
  add(path_21626946, "AwsAccountId", newJString(AwsAccountId))
  add(query_21626947, "max-results", newJInt(maxResults))
  add(query_21626947, "next-token", newJString(nextToken))
  add(path_21626946, "UserName", newJString(UserName))
  add(path_21626946, "Namespace", newJString(Namespace))
  result = call_21626945.call(path_21626946, query_21626947, nil, nil, nil)

var listIAMPolicyAssignmentsForUser* = Call_ListIAMPolicyAssignmentsForUser_21626929(
    name: "listIAMPolicyAssignmentsForUser", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}/iam-policy-assignments",
    validator: validate_ListIAMPolicyAssignmentsForUser_21626930, base: "/",
    makeUrl: url_ListIAMPolicyAssignmentsForUser_21626931,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIngestions_21626948 = ref object of OpenApiRestCall_21625435
proc url_ListIngestions_21626950(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/data-sets/"),
               (kind: VariableSegment, value: "DataSetId"),
               (kind: ConstantSegment, value: "/ingestions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListIngestions_21626949(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the history of SPICE ingestions for a dataset.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID.
  ##   DataSetId: JString (required)
  ##            : The ID of the dataset used in the ingestion.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_21626951 = path.getOrDefault("AwsAccountId")
  valid_21626951 = validateParameter(valid_21626951, JString, required = true,
                                   default = nil)
  if valid_21626951 != nil:
    section.add "AwsAccountId", valid_21626951
  var valid_21626952 = path.getOrDefault("DataSetId")
  valid_21626952 = validateParameter(valid_21626952, JString, required = true,
                                   default = nil)
  if valid_21626952 != nil:
    section.add "DataSetId", valid_21626952
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   max-results: JInt
  ##              : The maximum number of results to be returned per request.
  ##   next-token: JString
  ##             : The token for the next set of results, or null if there are no more results.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626953 = query.getOrDefault("NextToken")
  valid_21626953 = validateParameter(valid_21626953, JString, required = false,
                                   default = nil)
  if valid_21626953 != nil:
    section.add "NextToken", valid_21626953
  var valid_21626954 = query.getOrDefault("max-results")
  valid_21626954 = validateParameter(valid_21626954, JInt, required = false,
                                   default = nil)
  if valid_21626954 != nil:
    section.add "max-results", valid_21626954
  var valid_21626955 = query.getOrDefault("next-token")
  valid_21626955 = validateParameter(valid_21626955, JString, required = false,
                                   default = nil)
  if valid_21626955 != nil:
    section.add "next-token", valid_21626955
  var valid_21626956 = query.getOrDefault("MaxResults")
  valid_21626956 = validateParameter(valid_21626956, JString, required = false,
                                   default = nil)
  if valid_21626956 != nil:
    section.add "MaxResults", valid_21626956
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626957 = header.getOrDefault("X-Amz-Date")
  valid_21626957 = validateParameter(valid_21626957, JString, required = false,
                                   default = nil)
  if valid_21626957 != nil:
    section.add "X-Amz-Date", valid_21626957
  var valid_21626958 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626958 = validateParameter(valid_21626958, JString, required = false,
                                   default = nil)
  if valid_21626958 != nil:
    section.add "X-Amz-Security-Token", valid_21626958
  var valid_21626959 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626959 = validateParameter(valid_21626959, JString, required = false,
                                   default = nil)
  if valid_21626959 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626959
  var valid_21626960 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626960 = validateParameter(valid_21626960, JString, required = false,
                                   default = nil)
  if valid_21626960 != nil:
    section.add "X-Amz-Algorithm", valid_21626960
  var valid_21626961 = header.getOrDefault("X-Amz-Signature")
  valid_21626961 = validateParameter(valid_21626961, JString, required = false,
                                   default = nil)
  if valid_21626961 != nil:
    section.add "X-Amz-Signature", valid_21626961
  var valid_21626962 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626962 = validateParameter(valid_21626962, JString, required = false,
                                   default = nil)
  if valid_21626962 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626962
  var valid_21626963 = header.getOrDefault("X-Amz-Credential")
  valid_21626963 = validateParameter(valid_21626963, JString, required = false,
                                   default = nil)
  if valid_21626963 != nil:
    section.add "X-Amz-Credential", valid_21626963
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626964: Call_ListIngestions_21626948; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the history of SPICE ingestions for a dataset.
  ## 
  let valid = call_21626964.validator(path, query, header, formData, body, _)
  let scheme = call_21626964.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626964.makeUrl(scheme.get, call_21626964.host, call_21626964.base,
                               call_21626964.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626964, uri, valid, _)

proc call*(call_21626965: Call_ListIngestions_21626948; AwsAccountId: string;
          DataSetId: string; NextToken: string = ""; maxResults: int = 0;
          nextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listIngestions
  ## Lists the history of SPICE ingestions for a dataset.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results to be returned per request.
  ##   nextToken: string
  ##            : The token for the next set of results, or null if there are no more results.
  ##   DataSetId: string (required)
  ##            : The ID of the dataset used in the ingestion.
  ##   MaxResults: string
  ##             : Pagination limit
  var path_21626966 = newJObject()
  var query_21626967 = newJObject()
  add(path_21626966, "AwsAccountId", newJString(AwsAccountId))
  add(query_21626967, "NextToken", newJString(NextToken))
  add(query_21626967, "max-results", newJInt(maxResults))
  add(query_21626967, "next-token", newJString(nextToken))
  add(path_21626966, "DataSetId", newJString(DataSetId))
  add(query_21626967, "MaxResults", newJString(MaxResults))
  result = call_21626965.call(path_21626966, query_21626967, nil, nil, nil)

var listIngestions* = Call_ListIngestions_21626948(name: "listIngestions",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}/ingestions",
    validator: validate_ListIngestions_21626949, base: "/",
    makeUrl: url_ListIngestions_21626950, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_21626982 = ref object of OpenApiRestCall_21625435
proc url_TagResource_21626984(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ResourceArn" in path, "`ResourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/resources/"),
               (kind: VariableSegment, value: "ResourceArn"),
               (kind: ConstantSegment, value: "/tags")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_21626983(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Assigns one or more tags (key-value pairs) to the specified QuickSight resource. </p> <p>Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values. You can use the <code>TagResource</code> operation with a resource that already has tags. If you specify a new tag key for the resource, this tag is appended to the list of tags associated with the resource. If you specify a tag key that is already associated with the resource, the new tag value that you specify replaces the previous value for that tag.</p> <p>You can associate as many as 50 tags with a resource. QuickSight supports tagging on data set, data source, dashboard, and template. </p> <p>Tagging for QuickSight works in a similar way to tagging for other AWS services, except for the following:</p> <ul> <li> <p>You can't use tags to track AWS costs for QuickSight. This restriction is because QuickSight costs are based on users and SPICE capacity, which aren't taggable resources.</p> </li> <li> <p>QuickSight doesn't currently support the Tag Editor for AWS Resource Groups.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ResourceArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the resource that you want to tag.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `ResourceArn` field"
  var valid_21626985 = path.getOrDefault("ResourceArn")
  valid_21626985 = validateParameter(valid_21626985, JString, required = true,
                                   default = nil)
  if valid_21626985 != nil:
    section.add "ResourceArn", valid_21626985
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626986 = header.getOrDefault("X-Amz-Date")
  valid_21626986 = validateParameter(valid_21626986, JString, required = false,
                                   default = nil)
  if valid_21626986 != nil:
    section.add "X-Amz-Date", valid_21626986
  var valid_21626987 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626987 = validateParameter(valid_21626987, JString, required = false,
                                   default = nil)
  if valid_21626987 != nil:
    section.add "X-Amz-Security-Token", valid_21626987
  var valid_21626988 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626988 = validateParameter(valid_21626988, JString, required = false,
                                   default = nil)
  if valid_21626988 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626988
  var valid_21626989 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626989 = validateParameter(valid_21626989, JString, required = false,
                                   default = nil)
  if valid_21626989 != nil:
    section.add "X-Amz-Algorithm", valid_21626989
  var valid_21626990 = header.getOrDefault("X-Amz-Signature")
  valid_21626990 = validateParameter(valid_21626990, JString, required = false,
                                   default = nil)
  if valid_21626990 != nil:
    section.add "X-Amz-Signature", valid_21626990
  var valid_21626991 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626991 = validateParameter(valid_21626991, JString, required = false,
                                   default = nil)
  if valid_21626991 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626991
  var valid_21626992 = header.getOrDefault("X-Amz-Credential")
  valid_21626992 = validateParameter(valid_21626992, JString, required = false,
                                   default = nil)
  if valid_21626992 != nil:
    section.add "X-Amz-Credential", valid_21626992
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626994: Call_TagResource_21626982; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Assigns one or more tags (key-value pairs) to the specified QuickSight resource. </p> <p>Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values. You can use the <code>TagResource</code> operation with a resource that already has tags. If you specify a new tag key for the resource, this tag is appended to the list of tags associated with the resource. If you specify a tag key that is already associated with the resource, the new tag value that you specify replaces the previous value for that tag.</p> <p>You can associate as many as 50 tags with a resource. QuickSight supports tagging on data set, data source, dashboard, and template. </p> <p>Tagging for QuickSight works in a similar way to tagging for other AWS services, except for the following:</p> <ul> <li> <p>You can't use tags to track AWS costs for QuickSight. This restriction is because QuickSight costs are based on users and SPICE capacity, which aren't taggable resources.</p> </li> <li> <p>QuickSight doesn't currently support the Tag Editor for AWS Resource Groups.</p> </li> </ul>
  ## 
  let valid = call_21626994.validator(path, query, header, formData, body, _)
  let scheme = call_21626994.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626994.makeUrl(scheme.get, call_21626994.host, call_21626994.base,
                               call_21626994.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626994, uri, valid, _)

proc call*(call_21626995: Call_TagResource_21626982; ResourceArn: string;
          body: JsonNode): Recallable =
  ## tagResource
  ## <p>Assigns one or more tags (key-value pairs) to the specified QuickSight resource. </p> <p>Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values. You can use the <code>TagResource</code> operation with a resource that already has tags. If you specify a new tag key for the resource, this tag is appended to the list of tags associated with the resource. If you specify a tag key that is already associated with the resource, the new tag value that you specify replaces the previous value for that tag.</p> <p>You can associate as many as 50 tags with a resource. QuickSight supports tagging on data set, data source, dashboard, and template. </p> <p>Tagging for QuickSight works in a similar way to tagging for other AWS services, except for the following:</p> <ul> <li> <p>You can't use tags to track AWS costs for QuickSight. This restriction is because QuickSight costs are based on users and SPICE capacity, which aren't taggable resources.</p> </li> <li> <p>QuickSight doesn't currently support the Tag Editor for AWS Resource Groups.</p> </li> </ul>
  ##   ResourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource that you want to tag.
  ##   body: JObject (required)
  var path_21626996 = newJObject()
  var body_21626997 = newJObject()
  add(path_21626996, "ResourceArn", newJString(ResourceArn))
  if body != nil:
    body_21626997 = body
  result = call_21626995.call(path_21626996, nil, nil, nil, body_21626997)

var tagResource* = Call_TagResource_21626982(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "quicksight.amazonaws.com",
    route: "/resources/{ResourceArn}/tags", validator: validate_TagResource_21626983,
    base: "/", makeUrl: url_TagResource_21626984,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_21626968 = ref object of OpenApiRestCall_21625435
proc url_ListTagsForResource_21626970(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ResourceArn" in path, "`ResourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/resources/"),
               (kind: VariableSegment, value: "ResourceArn"),
               (kind: ConstantSegment, value: "/tags")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_21626969(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the tags assigned to a resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ResourceArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the resource that you want a list of tags for.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `ResourceArn` field"
  var valid_21626971 = path.getOrDefault("ResourceArn")
  valid_21626971 = validateParameter(valid_21626971, JString, required = true,
                                   default = nil)
  if valid_21626971 != nil:
    section.add "ResourceArn", valid_21626971
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626972 = header.getOrDefault("X-Amz-Date")
  valid_21626972 = validateParameter(valid_21626972, JString, required = false,
                                   default = nil)
  if valid_21626972 != nil:
    section.add "X-Amz-Date", valid_21626972
  var valid_21626973 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626973 = validateParameter(valid_21626973, JString, required = false,
                                   default = nil)
  if valid_21626973 != nil:
    section.add "X-Amz-Security-Token", valid_21626973
  var valid_21626974 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626974 = validateParameter(valid_21626974, JString, required = false,
                                   default = nil)
  if valid_21626974 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626974
  var valid_21626975 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626975 = validateParameter(valid_21626975, JString, required = false,
                                   default = nil)
  if valid_21626975 != nil:
    section.add "X-Amz-Algorithm", valid_21626975
  var valid_21626976 = header.getOrDefault("X-Amz-Signature")
  valid_21626976 = validateParameter(valid_21626976, JString, required = false,
                                   default = nil)
  if valid_21626976 != nil:
    section.add "X-Amz-Signature", valid_21626976
  var valid_21626977 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626977 = validateParameter(valid_21626977, JString, required = false,
                                   default = nil)
  if valid_21626977 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626977
  var valid_21626978 = header.getOrDefault("X-Amz-Credential")
  valid_21626978 = validateParameter(valid_21626978, JString, required = false,
                                   default = nil)
  if valid_21626978 != nil:
    section.add "X-Amz-Credential", valid_21626978
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626979: Call_ListTagsForResource_21626968; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the tags assigned to a resource.
  ## 
  let valid = call_21626979.validator(path, query, header, formData, body, _)
  let scheme = call_21626979.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626979.makeUrl(scheme.get, call_21626979.host, call_21626979.base,
                               call_21626979.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626979, uri, valid, _)

proc call*(call_21626980: Call_ListTagsForResource_21626968; ResourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists the tags assigned to a resource.
  ##   ResourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource that you want a list of tags for.
  var path_21626981 = newJObject()
  add(path_21626981, "ResourceArn", newJString(ResourceArn))
  result = call_21626980.call(path_21626981, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_21626968(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com", route: "/resources/{ResourceArn}/tags",
    validator: validate_ListTagsForResource_21626969, base: "/",
    makeUrl: url_ListTagsForResource_21626970,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTemplateAliases_21626998 = ref object of OpenApiRestCall_21625435
proc url_ListTemplateAliases_21627000(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "TemplateId" in path, "`TemplateId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/templates/"),
               (kind: VariableSegment, value: "TemplateId"),
               (kind: ConstantSegment, value: "/aliases")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTemplateAliases_21626999(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists all the aliases of a template.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account that contains the template aliases that you're listing.
  ##   TemplateId: JString (required)
  ##             : The ID for the template.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_21627001 = path.getOrDefault("AwsAccountId")
  valid_21627001 = validateParameter(valid_21627001, JString, required = true,
                                   default = nil)
  if valid_21627001 != nil:
    section.add "AwsAccountId", valid_21627001
  var valid_21627002 = path.getOrDefault("TemplateId")
  valid_21627002 = validateParameter(valid_21627002, JString, required = true,
                                   default = nil)
  if valid_21627002 != nil:
    section.add "TemplateId", valid_21627002
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   max-result: JInt
  ##             : The maximum number of results to be returned per request.
  ##   next-token: JString
  ##             : The token for the next set of results, or null if there are no more results.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21627003 = query.getOrDefault("NextToken")
  valid_21627003 = validateParameter(valid_21627003, JString, required = false,
                                   default = nil)
  if valid_21627003 != nil:
    section.add "NextToken", valid_21627003
  var valid_21627004 = query.getOrDefault("max-result")
  valid_21627004 = validateParameter(valid_21627004, JInt, required = false,
                                   default = nil)
  if valid_21627004 != nil:
    section.add "max-result", valid_21627004
  var valid_21627005 = query.getOrDefault("next-token")
  valid_21627005 = validateParameter(valid_21627005, JString, required = false,
                                   default = nil)
  if valid_21627005 != nil:
    section.add "next-token", valid_21627005
  var valid_21627006 = query.getOrDefault("MaxResults")
  valid_21627006 = validateParameter(valid_21627006, JString, required = false,
                                   default = nil)
  if valid_21627006 != nil:
    section.add "MaxResults", valid_21627006
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627007 = header.getOrDefault("X-Amz-Date")
  valid_21627007 = validateParameter(valid_21627007, JString, required = false,
                                   default = nil)
  if valid_21627007 != nil:
    section.add "X-Amz-Date", valid_21627007
  var valid_21627008 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627008 = validateParameter(valid_21627008, JString, required = false,
                                   default = nil)
  if valid_21627008 != nil:
    section.add "X-Amz-Security-Token", valid_21627008
  var valid_21627009 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627009 = validateParameter(valid_21627009, JString, required = false,
                                   default = nil)
  if valid_21627009 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627009
  var valid_21627010 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627010 = validateParameter(valid_21627010, JString, required = false,
                                   default = nil)
  if valid_21627010 != nil:
    section.add "X-Amz-Algorithm", valid_21627010
  var valid_21627011 = header.getOrDefault("X-Amz-Signature")
  valid_21627011 = validateParameter(valid_21627011, JString, required = false,
                                   default = nil)
  if valid_21627011 != nil:
    section.add "X-Amz-Signature", valid_21627011
  var valid_21627012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627012 = validateParameter(valid_21627012, JString, required = false,
                                   default = nil)
  if valid_21627012 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627012
  var valid_21627013 = header.getOrDefault("X-Amz-Credential")
  valid_21627013 = validateParameter(valid_21627013, JString, required = false,
                                   default = nil)
  if valid_21627013 != nil:
    section.add "X-Amz-Credential", valid_21627013
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627014: Call_ListTemplateAliases_21626998; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all the aliases of a template.
  ## 
  let valid = call_21627014.validator(path, query, header, formData, body, _)
  let scheme = call_21627014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627014.makeUrl(scheme.get, call_21627014.host, call_21627014.base,
                               call_21627014.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627014, uri, valid, _)

proc call*(call_21627015: Call_ListTemplateAliases_21626998; AwsAccountId: string;
          TemplateId: string; NextToken: string = ""; maxResult: int = 0;
          nextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listTemplateAliases
  ## Lists all the aliases of a template.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the template aliases that you're listing.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResult: int
  ##            : The maximum number of results to be returned per request.
  ##   TemplateId: string (required)
  ##             : The ID for the template.
  ##   nextToken: string
  ##            : The token for the next set of results, or null if there are no more results.
  ##   MaxResults: string
  ##             : Pagination limit
  var path_21627016 = newJObject()
  var query_21627017 = newJObject()
  add(path_21627016, "AwsAccountId", newJString(AwsAccountId))
  add(query_21627017, "NextToken", newJString(NextToken))
  add(query_21627017, "max-result", newJInt(maxResult))
  add(path_21627016, "TemplateId", newJString(TemplateId))
  add(query_21627017, "next-token", newJString(nextToken))
  add(query_21627017, "MaxResults", newJString(MaxResults))
  result = call_21627015.call(path_21627016, query_21627017, nil, nil, nil)

var listTemplateAliases* = Call_ListTemplateAliases_21626998(
    name: "listTemplateAliases", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates/{TemplateId}/aliases",
    validator: validate_ListTemplateAliases_21626999, base: "/",
    makeUrl: url_ListTemplateAliases_21627000,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTemplateVersions_21627018 = ref object of OpenApiRestCall_21625435
proc url_ListTemplateVersions_21627020(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "TemplateId" in path, "`TemplateId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/templates/"),
               (kind: VariableSegment, value: "TemplateId"),
               (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTemplateVersions_21627019(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists all the versions of the templates in the current Amazon QuickSight account.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account that contains the templates that you're listing.
  ##   TemplateId: JString (required)
  ##             : The ID for the template.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_21627021 = path.getOrDefault("AwsAccountId")
  valid_21627021 = validateParameter(valid_21627021, JString, required = true,
                                   default = nil)
  if valid_21627021 != nil:
    section.add "AwsAccountId", valid_21627021
  var valid_21627022 = path.getOrDefault("TemplateId")
  valid_21627022 = validateParameter(valid_21627022, JString, required = true,
                                   default = nil)
  if valid_21627022 != nil:
    section.add "TemplateId", valid_21627022
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   max-results: JInt
  ##              : The maximum number of results to be returned per request.
  ##   next-token: JString
  ##             : The token for the next set of results, or null if there are no more results.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21627023 = query.getOrDefault("NextToken")
  valid_21627023 = validateParameter(valid_21627023, JString, required = false,
                                   default = nil)
  if valid_21627023 != nil:
    section.add "NextToken", valid_21627023
  var valid_21627024 = query.getOrDefault("max-results")
  valid_21627024 = validateParameter(valid_21627024, JInt, required = false,
                                   default = nil)
  if valid_21627024 != nil:
    section.add "max-results", valid_21627024
  var valid_21627025 = query.getOrDefault("next-token")
  valid_21627025 = validateParameter(valid_21627025, JString, required = false,
                                   default = nil)
  if valid_21627025 != nil:
    section.add "next-token", valid_21627025
  var valid_21627026 = query.getOrDefault("MaxResults")
  valid_21627026 = validateParameter(valid_21627026, JString, required = false,
                                   default = nil)
  if valid_21627026 != nil:
    section.add "MaxResults", valid_21627026
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627027 = header.getOrDefault("X-Amz-Date")
  valid_21627027 = validateParameter(valid_21627027, JString, required = false,
                                   default = nil)
  if valid_21627027 != nil:
    section.add "X-Amz-Date", valid_21627027
  var valid_21627028 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627028 = validateParameter(valid_21627028, JString, required = false,
                                   default = nil)
  if valid_21627028 != nil:
    section.add "X-Amz-Security-Token", valid_21627028
  var valid_21627029 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627029 = validateParameter(valid_21627029, JString, required = false,
                                   default = nil)
  if valid_21627029 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627029
  var valid_21627030 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627030 = validateParameter(valid_21627030, JString, required = false,
                                   default = nil)
  if valid_21627030 != nil:
    section.add "X-Amz-Algorithm", valid_21627030
  var valid_21627031 = header.getOrDefault("X-Amz-Signature")
  valid_21627031 = validateParameter(valid_21627031, JString, required = false,
                                   default = nil)
  if valid_21627031 != nil:
    section.add "X-Amz-Signature", valid_21627031
  var valid_21627032 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627032 = validateParameter(valid_21627032, JString, required = false,
                                   default = nil)
  if valid_21627032 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627032
  var valid_21627033 = header.getOrDefault("X-Amz-Credential")
  valid_21627033 = validateParameter(valid_21627033, JString, required = false,
                                   default = nil)
  if valid_21627033 != nil:
    section.add "X-Amz-Credential", valid_21627033
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627034: Call_ListTemplateVersions_21627018; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all the versions of the templates in the current Amazon QuickSight account.
  ## 
  let valid = call_21627034.validator(path, query, header, formData, body, _)
  let scheme = call_21627034.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627034.makeUrl(scheme.get, call_21627034.host, call_21627034.base,
                               call_21627034.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627034, uri, valid, _)

proc call*(call_21627035: Call_ListTemplateVersions_21627018; AwsAccountId: string;
          TemplateId: string; NextToken: string = ""; maxResults: int = 0;
          nextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listTemplateVersions
  ## Lists all the versions of the templates in the current Amazon QuickSight account.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the templates that you're listing.
  ##   NextToken: string
  ##            : Pagination token
  ##   TemplateId: string (required)
  ##             : The ID for the template.
  ##   maxResults: int
  ##             : The maximum number of results to be returned per request.
  ##   nextToken: string
  ##            : The token for the next set of results, or null if there are no more results.
  ##   MaxResults: string
  ##             : Pagination limit
  var path_21627036 = newJObject()
  var query_21627037 = newJObject()
  add(path_21627036, "AwsAccountId", newJString(AwsAccountId))
  add(query_21627037, "NextToken", newJString(NextToken))
  add(path_21627036, "TemplateId", newJString(TemplateId))
  add(query_21627037, "max-results", newJInt(maxResults))
  add(query_21627037, "next-token", newJString(nextToken))
  add(query_21627037, "MaxResults", newJString(MaxResults))
  result = call_21627035.call(path_21627036, query_21627037, nil, nil, nil)

var listTemplateVersions* = Call_ListTemplateVersions_21627018(
    name: "listTemplateVersions", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates/{TemplateId}/versions",
    validator: validate_ListTemplateVersions_21627019, base: "/",
    makeUrl: url_ListTemplateVersions_21627020,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTemplates_21627038 = ref object of OpenApiRestCall_21625435
proc url_ListTemplates_21627040(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/templates")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTemplates_21627039(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Lists all the templates in the current Amazon QuickSight account.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account that contains the templates that you're listing.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_21627041 = path.getOrDefault("AwsAccountId")
  valid_21627041 = validateParameter(valid_21627041, JString, required = true,
                                   default = nil)
  if valid_21627041 != nil:
    section.add "AwsAccountId", valid_21627041
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   max-result: JInt
  ##             : The maximum number of results to be returned per request.
  ##   next-token: JString
  ##             : The token for the next set of results, or null if there are no more results.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21627042 = query.getOrDefault("NextToken")
  valid_21627042 = validateParameter(valid_21627042, JString, required = false,
                                   default = nil)
  if valid_21627042 != nil:
    section.add "NextToken", valid_21627042
  var valid_21627043 = query.getOrDefault("max-result")
  valid_21627043 = validateParameter(valid_21627043, JInt, required = false,
                                   default = nil)
  if valid_21627043 != nil:
    section.add "max-result", valid_21627043
  var valid_21627044 = query.getOrDefault("next-token")
  valid_21627044 = validateParameter(valid_21627044, JString, required = false,
                                   default = nil)
  if valid_21627044 != nil:
    section.add "next-token", valid_21627044
  var valid_21627045 = query.getOrDefault("MaxResults")
  valid_21627045 = validateParameter(valid_21627045, JString, required = false,
                                   default = nil)
  if valid_21627045 != nil:
    section.add "MaxResults", valid_21627045
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627046 = header.getOrDefault("X-Amz-Date")
  valid_21627046 = validateParameter(valid_21627046, JString, required = false,
                                   default = nil)
  if valid_21627046 != nil:
    section.add "X-Amz-Date", valid_21627046
  var valid_21627047 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627047 = validateParameter(valid_21627047, JString, required = false,
                                   default = nil)
  if valid_21627047 != nil:
    section.add "X-Amz-Security-Token", valid_21627047
  var valid_21627048 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627048 = validateParameter(valid_21627048, JString, required = false,
                                   default = nil)
  if valid_21627048 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627048
  var valid_21627049 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627049 = validateParameter(valid_21627049, JString, required = false,
                                   default = nil)
  if valid_21627049 != nil:
    section.add "X-Amz-Algorithm", valid_21627049
  var valid_21627050 = header.getOrDefault("X-Amz-Signature")
  valid_21627050 = validateParameter(valid_21627050, JString, required = false,
                                   default = nil)
  if valid_21627050 != nil:
    section.add "X-Amz-Signature", valid_21627050
  var valid_21627051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627051 = validateParameter(valid_21627051, JString, required = false,
                                   default = nil)
  if valid_21627051 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627051
  var valid_21627052 = header.getOrDefault("X-Amz-Credential")
  valid_21627052 = validateParameter(valid_21627052, JString, required = false,
                                   default = nil)
  if valid_21627052 != nil:
    section.add "X-Amz-Credential", valid_21627052
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627053: Call_ListTemplates_21627038; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all the templates in the current Amazon QuickSight account.
  ## 
  let valid = call_21627053.validator(path, query, header, formData, body, _)
  let scheme = call_21627053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627053.makeUrl(scheme.get, call_21627053.host, call_21627053.base,
                               call_21627053.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627053, uri, valid, _)

proc call*(call_21627054: Call_ListTemplates_21627038; AwsAccountId: string;
          NextToken: string = ""; maxResult: int = 0; nextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listTemplates
  ## Lists all the templates in the current Amazon QuickSight account.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the templates that you're listing.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResult: int
  ##            : The maximum number of results to be returned per request.
  ##   nextToken: string
  ##            : The token for the next set of results, or null if there are no more results.
  ##   MaxResults: string
  ##             : Pagination limit
  var path_21627055 = newJObject()
  var query_21627056 = newJObject()
  add(path_21627055, "AwsAccountId", newJString(AwsAccountId))
  add(query_21627056, "NextToken", newJString(NextToken))
  add(query_21627056, "max-result", newJInt(maxResult))
  add(query_21627056, "next-token", newJString(nextToken))
  add(query_21627056, "MaxResults", newJString(MaxResults))
  result = call_21627054.call(path_21627055, query_21627056, nil, nil, nil)

var listTemplates* = Call_ListTemplates_21627038(name: "listTemplates",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates",
    validator: validate_ListTemplates_21627039, base: "/",
    makeUrl: url_ListTemplates_21627040, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUserGroups_21627057 = ref object of OpenApiRestCall_21625435
proc url_ListUserGroups_21627059(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "Namespace" in path, "`Namespace` is a required path parameter"
  assert "UserName" in path, "`UserName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/namespaces/"),
               (kind: VariableSegment, value: "Namespace"),
               (kind: ConstantSegment, value: "/users/"),
               (kind: VariableSegment, value: "UserName"),
               (kind: ConstantSegment, value: "/groups")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListUserGroups_21627058(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the Amazon QuickSight groups that an Amazon QuickSight user is a member of.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   UserName: JString (required)
  ##           : The Amazon QuickSight user name that you want to list group memberships for.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_21627060 = path.getOrDefault("AwsAccountId")
  valid_21627060 = validateParameter(valid_21627060, JString, required = true,
                                   default = nil)
  if valid_21627060 != nil:
    section.add "AwsAccountId", valid_21627060
  var valid_21627061 = path.getOrDefault("UserName")
  valid_21627061 = validateParameter(valid_21627061, JString, required = true,
                                   default = nil)
  if valid_21627061 != nil:
    section.add "UserName", valid_21627061
  var valid_21627062 = path.getOrDefault("Namespace")
  valid_21627062 = validateParameter(valid_21627062, JString, required = true,
                                   default = nil)
  if valid_21627062 != nil:
    section.add "Namespace", valid_21627062
  result.add "path", section
  ## parameters in `query` object:
  ##   max-results: JInt
  ##              : The maximum number of results to return from this request.
  ##   next-token: JString
  ##             : A pagination token that can be used in a subsequent request.
  section = newJObject()
  var valid_21627063 = query.getOrDefault("max-results")
  valid_21627063 = validateParameter(valid_21627063, JInt, required = false,
                                   default = nil)
  if valid_21627063 != nil:
    section.add "max-results", valid_21627063
  var valid_21627064 = query.getOrDefault("next-token")
  valid_21627064 = validateParameter(valid_21627064, JString, required = false,
                                   default = nil)
  if valid_21627064 != nil:
    section.add "next-token", valid_21627064
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627065 = header.getOrDefault("X-Amz-Date")
  valid_21627065 = validateParameter(valid_21627065, JString, required = false,
                                   default = nil)
  if valid_21627065 != nil:
    section.add "X-Amz-Date", valid_21627065
  var valid_21627066 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627066 = validateParameter(valid_21627066, JString, required = false,
                                   default = nil)
  if valid_21627066 != nil:
    section.add "X-Amz-Security-Token", valid_21627066
  var valid_21627067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627067 = validateParameter(valid_21627067, JString, required = false,
                                   default = nil)
  if valid_21627067 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627067
  var valid_21627068 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627068 = validateParameter(valid_21627068, JString, required = false,
                                   default = nil)
  if valid_21627068 != nil:
    section.add "X-Amz-Algorithm", valid_21627068
  var valid_21627069 = header.getOrDefault("X-Amz-Signature")
  valid_21627069 = validateParameter(valid_21627069, JString, required = false,
                                   default = nil)
  if valid_21627069 != nil:
    section.add "X-Amz-Signature", valid_21627069
  var valid_21627070 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627070 = validateParameter(valid_21627070, JString, required = false,
                                   default = nil)
  if valid_21627070 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627070
  var valid_21627071 = header.getOrDefault("X-Amz-Credential")
  valid_21627071 = validateParameter(valid_21627071, JString, required = false,
                                   default = nil)
  if valid_21627071 != nil:
    section.add "X-Amz-Credential", valid_21627071
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627072: Call_ListUserGroups_21627057; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the Amazon QuickSight groups that an Amazon QuickSight user is a member of.
  ## 
  let valid = call_21627072.validator(path, query, header, formData, body, _)
  let scheme = call_21627072.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627072.makeUrl(scheme.get, call_21627072.host, call_21627072.base,
                               call_21627072.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627072, uri, valid, _)

proc call*(call_21627073: Call_ListUserGroups_21627057; AwsAccountId: string;
          UserName: string; Namespace: string; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listUserGroups
  ## Lists the Amazon QuickSight groups that an Amazon QuickSight user is a member of.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   maxResults: int
  ##             : The maximum number of results to return from this request.
  ##   nextToken: string
  ##            : A pagination token that can be used in a subsequent request.
  ##   UserName: string (required)
  ##           : The Amazon QuickSight user name that you want to list group memberships for.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  var path_21627074 = newJObject()
  var query_21627075 = newJObject()
  add(path_21627074, "AwsAccountId", newJString(AwsAccountId))
  add(query_21627075, "max-results", newJInt(maxResults))
  add(query_21627075, "next-token", newJString(nextToken))
  add(path_21627074, "UserName", newJString(UserName))
  add(path_21627074, "Namespace", newJString(Namespace))
  result = call_21627073.call(path_21627074, query_21627075, nil, nil, nil)

var listUserGroups* = Call_ListUserGroups_21627057(name: "listUserGroups",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}/groups",
    validator: validate_ListUserGroups_21627058, base: "/",
    makeUrl: url_ListUserGroups_21627059, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterUser_21627094 = ref object of OpenApiRestCall_21625435
proc url_RegisterUser_21627096(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "Namespace" in path, "`Namespace` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/namespaces/"),
               (kind: VariableSegment, value: "Namespace"),
               (kind: ConstantSegment, value: "/users")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_RegisterUser_21627095(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Creates an Amazon QuickSight user, whose identity is associated with the AWS Identity and Access Management (IAM) identity or role specified in the request. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_21627097 = path.getOrDefault("AwsAccountId")
  valid_21627097 = validateParameter(valid_21627097, JString, required = true,
                                   default = nil)
  if valid_21627097 != nil:
    section.add "AwsAccountId", valid_21627097
  var valid_21627098 = path.getOrDefault("Namespace")
  valid_21627098 = validateParameter(valid_21627098, JString, required = true,
                                   default = nil)
  if valid_21627098 != nil:
    section.add "Namespace", valid_21627098
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627099 = header.getOrDefault("X-Amz-Date")
  valid_21627099 = validateParameter(valid_21627099, JString, required = false,
                                   default = nil)
  if valid_21627099 != nil:
    section.add "X-Amz-Date", valid_21627099
  var valid_21627100 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627100 = validateParameter(valid_21627100, JString, required = false,
                                   default = nil)
  if valid_21627100 != nil:
    section.add "X-Amz-Security-Token", valid_21627100
  var valid_21627101 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627101 = validateParameter(valid_21627101, JString, required = false,
                                   default = nil)
  if valid_21627101 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627101
  var valid_21627102 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627102 = validateParameter(valid_21627102, JString, required = false,
                                   default = nil)
  if valid_21627102 != nil:
    section.add "X-Amz-Algorithm", valid_21627102
  var valid_21627103 = header.getOrDefault("X-Amz-Signature")
  valid_21627103 = validateParameter(valid_21627103, JString, required = false,
                                   default = nil)
  if valid_21627103 != nil:
    section.add "X-Amz-Signature", valid_21627103
  var valid_21627104 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627104 = validateParameter(valid_21627104, JString, required = false,
                                   default = nil)
  if valid_21627104 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627104
  var valid_21627105 = header.getOrDefault("X-Amz-Credential")
  valid_21627105 = validateParameter(valid_21627105, JString, required = false,
                                   default = nil)
  if valid_21627105 != nil:
    section.add "X-Amz-Credential", valid_21627105
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627107: Call_RegisterUser_21627094; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an Amazon QuickSight user, whose identity is associated with the AWS Identity and Access Management (IAM) identity or role specified in the request. 
  ## 
  let valid = call_21627107.validator(path, query, header, formData, body, _)
  let scheme = call_21627107.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627107.makeUrl(scheme.get, call_21627107.host, call_21627107.base,
                               call_21627107.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627107, uri, valid, _)

proc call*(call_21627108: Call_RegisterUser_21627094; AwsAccountId: string;
          body: JsonNode; Namespace: string): Recallable =
  ## registerUser
  ## Creates an Amazon QuickSight user, whose identity is associated with the AWS Identity and Access Management (IAM) identity or role specified in the request. 
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   body: JObject (required)
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  var path_21627109 = newJObject()
  var body_21627110 = newJObject()
  add(path_21627109, "AwsAccountId", newJString(AwsAccountId))
  if body != nil:
    body_21627110 = body
  add(path_21627109, "Namespace", newJString(Namespace))
  result = call_21627108.call(path_21627109, nil, nil, nil, body_21627110)

var registerUser* = Call_RegisterUser_21627094(name: "registerUser",
    meth: HttpMethod.HttpPost, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users",
    validator: validate_RegisterUser_21627095, base: "/", makeUrl: url_RegisterUser_21627096,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsers_21627076 = ref object of OpenApiRestCall_21625435
proc url_ListUsers_21627078(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "Namespace" in path, "`Namespace` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/namespaces/"),
               (kind: VariableSegment, value: "Namespace"),
               (kind: ConstantSegment, value: "/users")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListUsers_21627077(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of all of the Amazon QuickSight users belonging to this account. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_21627079 = path.getOrDefault("AwsAccountId")
  valid_21627079 = validateParameter(valid_21627079, JString, required = true,
                                   default = nil)
  if valid_21627079 != nil:
    section.add "AwsAccountId", valid_21627079
  var valid_21627080 = path.getOrDefault("Namespace")
  valid_21627080 = validateParameter(valid_21627080, JString, required = true,
                                   default = nil)
  if valid_21627080 != nil:
    section.add "Namespace", valid_21627080
  result.add "path", section
  ## parameters in `query` object:
  ##   max-results: JInt
  ##              : The maximum number of results to return from this request.
  ##   next-token: JString
  ##             : A pagination token that can be used in a subsequent request.
  section = newJObject()
  var valid_21627081 = query.getOrDefault("max-results")
  valid_21627081 = validateParameter(valid_21627081, JInt, required = false,
                                   default = nil)
  if valid_21627081 != nil:
    section.add "max-results", valid_21627081
  var valid_21627082 = query.getOrDefault("next-token")
  valid_21627082 = validateParameter(valid_21627082, JString, required = false,
                                   default = nil)
  if valid_21627082 != nil:
    section.add "next-token", valid_21627082
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627083 = header.getOrDefault("X-Amz-Date")
  valid_21627083 = validateParameter(valid_21627083, JString, required = false,
                                   default = nil)
  if valid_21627083 != nil:
    section.add "X-Amz-Date", valid_21627083
  var valid_21627084 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627084 = validateParameter(valid_21627084, JString, required = false,
                                   default = nil)
  if valid_21627084 != nil:
    section.add "X-Amz-Security-Token", valid_21627084
  var valid_21627085 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627085 = validateParameter(valid_21627085, JString, required = false,
                                   default = nil)
  if valid_21627085 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627085
  var valid_21627086 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627086 = validateParameter(valid_21627086, JString, required = false,
                                   default = nil)
  if valid_21627086 != nil:
    section.add "X-Amz-Algorithm", valid_21627086
  var valid_21627087 = header.getOrDefault("X-Amz-Signature")
  valid_21627087 = validateParameter(valid_21627087, JString, required = false,
                                   default = nil)
  if valid_21627087 != nil:
    section.add "X-Amz-Signature", valid_21627087
  var valid_21627088 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627088 = validateParameter(valid_21627088, JString, required = false,
                                   default = nil)
  if valid_21627088 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627088
  var valid_21627089 = header.getOrDefault("X-Amz-Credential")
  valid_21627089 = validateParameter(valid_21627089, JString, required = false,
                                   default = nil)
  if valid_21627089 != nil:
    section.add "X-Amz-Credential", valid_21627089
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627090: Call_ListUsers_21627076; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of all of the Amazon QuickSight users belonging to this account. 
  ## 
  let valid = call_21627090.validator(path, query, header, formData, body, _)
  let scheme = call_21627090.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627090.makeUrl(scheme.get, call_21627090.host, call_21627090.base,
                               call_21627090.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627090, uri, valid, _)

proc call*(call_21627091: Call_ListUsers_21627076; AwsAccountId: string;
          Namespace: string; maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listUsers
  ## Returns a list of all of the Amazon QuickSight users belonging to this account. 
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   maxResults: int
  ##             : The maximum number of results to return from this request.
  ##   nextToken: string
  ##            : A pagination token that can be used in a subsequent request.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  var path_21627092 = newJObject()
  var query_21627093 = newJObject()
  add(path_21627092, "AwsAccountId", newJString(AwsAccountId))
  add(query_21627093, "max-results", newJInt(maxResults))
  add(query_21627093, "next-token", newJString(nextToken))
  add(path_21627092, "Namespace", newJString(Namespace))
  result = call_21627091.call(path_21627092, query_21627093, nil, nil, nil)

var listUsers* = Call_ListUsers_21627076(name: "listUsers", meth: HttpMethod.HttpGet,
                                      host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users",
                                      validator: validate_ListUsers_21627077,
                                      base: "/", makeUrl: url_ListUsers_21627078,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_21627111 = ref object of OpenApiRestCall_21625435
proc url_UntagResource_21627113(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ResourceArn" in path, "`ResourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/resources/"),
               (kind: VariableSegment, value: "ResourceArn"),
               (kind: ConstantSegment, value: "/tags#keys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_21627112(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Removes a tag or tags from a resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ResourceArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the resource that you want to untag.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `ResourceArn` field"
  var valid_21627114 = path.getOrDefault("ResourceArn")
  valid_21627114 = validateParameter(valid_21627114, JString, required = true,
                                   default = nil)
  if valid_21627114 != nil:
    section.add "ResourceArn", valid_21627114
  result.add "path", section
  ## parameters in `query` object:
  ##   keys: JArray (required)
  ##       : The keys of the key-value pairs for the resource tag or tags assigned to the resource.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `keys` field"
  var valid_21627115 = query.getOrDefault("keys")
  valid_21627115 = validateParameter(valid_21627115, JArray, required = true,
                                   default = nil)
  if valid_21627115 != nil:
    section.add "keys", valid_21627115
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627116 = header.getOrDefault("X-Amz-Date")
  valid_21627116 = validateParameter(valid_21627116, JString, required = false,
                                   default = nil)
  if valid_21627116 != nil:
    section.add "X-Amz-Date", valid_21627116
  var valid_21627117 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627117 = validateParameter(valid_21627117, JString, required = false,
                                   default = nil)
  if valid_21627117 != nil:
    section.add "X-Amz-Security-Token", valid_21627117
  var valid_21627118 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627118 = validateParameter(valid_21627118, JString, required = false,
                                   default = nil)
  if valid_21627118 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627118
  var valid_21627119 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627119 = validateParameter(valid_21627119, JString, required = false,
                                   default = nil)
  if valid_21627119 != nil:
    section.add "X-Amz-Algorithm", valid_21627119
  var valid_21627120 = header.getOrDefault("X-Amz-Signature")
  valid_21627120 = validateParameter(valid_21627120, JString, required = false,
                                   default = nil)
  if valid_21627120 != nil:
    section.add "X-Amz-Signature", valid_21627120
  var valid_21627121 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627121 = validateParameter(valid_21627121, JString, required = false,
                                   default = nil)
  if valid_21627121 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627121
  var valid_21627122 = header.getOrDefault("X-Amz-Credential")
  valid_21627122 = validateParameter(valid_21627122, JString, required = false,
                                   default = nil)
  if valid_21627122 != nil:
    section.add "X-Amz-Credential", valid_21627122
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627123: Call_UntagResource_21627111; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes a tag or tags from a resource.
  ## 
  let valid = call_21627123.validator(path, query, header, formData, body, _)
  let scheme = call_21627123.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627123.makeUrl(scheme.get, call_21627123.host, call_21627123.base,
                               call_21627123.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627123, uri, valid, _)

proc call*(call_21627124: Call_UntagResource_21627111; keys: JsonNode;
          ResourceArn: string): Recallable =
  ## untagResource
  ## Removes a tag or tags from a resource.
  ##   keys: JArray (required)
  ##       : The keys of the key-value pairs for the resource tag or tags assigned to the resource.
  ##   ResourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource that you want to untag.
  var path_21627125 = newJObject()
  var query_21627126 = newJObject()
  if keys != nil:
    query_21627126.add "keys", keys
  add(path_21627125, "ResourceArn", newJString(ResourceArn))
  result = call_21627124.call(path_21627125, query_21627126, nil, nil, nil)

var untagResource* = Call_UntagResource_21627111(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "quicksight.amazonaws.com",
    route: "/resources/{ResourceArn}/tags#keys",
    validator: validate_UntagResource_21627112, base: "/",
    makeUrl: url_UntagResource_21627113, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDashboardPublishedVersion_21627127 = ref object of OpenApiRestCall_21625435
proc url_UpdateDashboardPublishedVersion_21627129(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "DashboardId" in path, "`DashboardId` is a required path parameter"
  assert "VersionNumber" in path, "`VersionNumber` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/dashboards/"),
               (kind: VariableSegment, value: "DashboardId"),
               (kind: ConstantSegment, value: "/versions/"),
               (kind: VariableSegment, value: "VersionNumber")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDashboardPublishedVersion_21627128(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Updates the published version of a dashboard.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account that contains the dashboard that you're updating.
  ##   DashboardId: JString (required)
  ##              : The ID for the dashboard.
  ##   VersionNumber: JInt (required)
  ##                : The version number of the dashboard.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_21627130 = path.getOrDefault("AwsAccountId")
  valid_21627130 = validateParameter(valid_21627130, JString, required = true,
                                   default = nil)
  if valid_21627130 != nil:
    section.add "AwsAccountId", valid_21627130
  var valid_21627131 = path.getOrDefault("DashboardId")
  valid_21627131 = validateParameter(valid_21627131, JString, required = true,
                                   default = nil)
  if valid_21627131 != nil:
    section.add "DashboardId", valid_21627131
  var valid_21627132 = path.getOrDefault("VersionNumber")
  valid_21627132 = validateParameter(valid_21627132, JInt, required = true,
                                   default = nil)
  if valid_21627132 != nil:
    section.add "VersionNumber", valid_21627132
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627133 = header.getOrDefault("X-Amz-Date")
  valid_21627133 = validateParameter(valid_21627133, JString, required = false,
                                   default = nil)
  if valid_21627133 != nil:
    section.add "X-Amz-Date", valid_21627133
  var valid_21627134 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627134 = validateParameter(valid_21627134, JString, required = false,
                                   default = nil)
  if valid_21627134 != nil:
    section.add "X-Amz-Security-Token", valid_21627134
  var valid_21627135 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627135 = validateParameter(valid_21627135, JString, required = false,
                                   default = nil)
  if valid_21627135 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627135
  var valid_21627136 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627136 = validateParameter(valid_21627136, JString, required = false,
                                   default = nil)
  if valid_21627136 != nil:
    section.add "X-Amz-Algorithm", valid_21627136
  var valid_21627137 = header.getOrDefault("X-Amz-Signature")
  valid_21627137 = validateParameter(valid_21627137, JString, required = false,
                                   default = nil)
  if valid_21627137 != nil:
    section.add "X-Amz-Signature", valid_21627137
  var valid_21627138 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627138 = validateParameter(valid_21627138, JString, required = false,
                                   default = nil)
  if valid_21627138 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627138
  var valid_21627139 = header.getOrDefault("X-Amz-Credential")
  valid_21627139 = validateParameter(valid_21627139, JString, required = false,
                                   default = nil)
  if valid_21627139 != nil:
    section.add "X-Amz-Credential", valid_21627139
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627140: Call_UpdateDashboardPublishedVersion_21627127;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the published version of a dashboard.
  ## 
  let valid = call_21627140.validator(path, query, header, formData, body, _)
  let scheme = call_21627140.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627140.makeUrl(scheme.get, call_21627140.host, call_21627140.base,
                               call_21627140.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627140, uri, valid, _)

proc call*(call_21627141: Call_UpdateDashboardPublishedVersion_21627127;
          AwsAccountId: string; DashboardId: string; VersionNumber: int): Recallable =
  ## updateDashboardPublishedVersion
  ## Updates the published version of a dashboard.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the dashboard that you're updating.
  ##   DashboardId: string (required)
  ##              : The ID for the dashboard.
  ##   VersionNumber: int (required)
  ##                : The version number of the dashboard.
  var path_21627142 = newJObject()
  add(path_21627142, "AwsAccountId", newJString(AwsAccountId))
  add(path_21627142, "DashboardId", newJString(DashboardId))
  add(path_21627142, "VersionNumber", newJInt(VersionNumber))
  result = call_21627141.call(path_21627142, nil, nil, nil, nil)

var updateDashboardPublishedVersion* = Call_UpdateDashboardPublishedVersion_21627127(
    name: "updateDashboardPublishedVersion", meth: HttpMethod.HttpPut,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}/versions/{VersionNumber}",
    validator: validate_UpdateDashboardPublishedVersion_21627128, base: "/",
    makeUrl: url_UpdateDashboardPublishedVersion_21627129,
    schemes: {Scheme.Https, Scheme.Http})
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
type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body = ""): Recallable {.
    base.} =
  ## the hook is a terrible earworm
  var
    headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
    text = body
  if text.len == 0 and "body" in input:
    text = input.getOrDefault("body").getStr
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  else:
    headers["content-md5"] = base64.encode text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

when not defined(ssl):
  {.error: "use ssl".}
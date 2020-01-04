
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_601389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601389): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateIngestion_601999 = ref object of OpenApiRestCall_601389
proc url_CreateIngestion_602001(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateIngestion_602000(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
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
  var valid_602002 = path.getOrDefault("AwsAccountId")
  valid_602002 = validateParameter(valid_602002, JString, required = true,
                                 default = nil)
  if valid_602002 != nil:
    section.add "AwsAccountId", valid_602002
  var valid_602003 = path.getOrDefault("DataSetId")
  valid_602003 = validateParameter(valid_602003, JString, required = true,
                                 default = nil)
  if valid_602003 != nil:
    section.add "DataSetId", valid_602003
  var valid_602004 = path.getOrDefault("IngestionId")
  valid_602004 = validateParameter(valid_602004, JString, required = true,
                                 default = nil)
  if valid_602004 != nil:
    section.add "IngestionId", valid_602004
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602005 = header.getOrDefault("X-Amz-Signature")
  valid_602005 = validateParameter(valid_602005, JString, required = false,
                                 default = nil)
  if valid_602005 != nil:
    section.add "X-Amz-Signature", valid_602005
  var valid_602006 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602006 = validateParameter(valid_602006, JString, required = false,
                                 default = nil)
  if valid_602006 != nil:
    section.add "X-Amz-Content-Sha256", valid_602006
  var valid_602007 = header.getOrDefault("X-Amz-Date")
  valid_602007 = validateParameter(valid_602007, JString, required = false,
                                 default = nil)
  if valid_602007 != nil:
    section.add "X-Amz-Date", valid_602007
  var valid_602008 = header.getOrDefault("X-Amz-Credential")
  valid_602008 = validateParameter(valid_602008, JString, required = false,
                                 default = nil)
  if valid_602008 != nil:
    section.add "X-Amz-Credential", valid_602008
  var valid_602009 = header.getOrDefault("X-Amz-Security-Token")
  valid_602009 = validateParameter(valid_602009, JString, required = false,
                                 default = nil)
  if valid_602009 != nil:
    section.add "X-Amz-Security-Token", valid_602009
  var valid_602010 = header.getOrDefault("X-Amz-Algorithm")
  valid_602010 = validateParameter(valid_602010, JString, required = false,
                                 default = nil)
  if valid_602010 != nil:
    section.add "X-Amz-Algorithm", valid_602010
  var valid_602011 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602011 = validateParameter(valid_602011, JString, required = false,
                                 default = nil)
  if valid_602011 != nil:
    section.add "X-Amz-SignedHeaders", valid_602011
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602012: Call_CreateIngestion_601999; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates and starts a new SPICE ingestion on a dataset</p> <p>Any ingestions operating on tagged datasets inherit the same tags automatically for use in access control. For an example, see <a href="https://aws.example.com/premiumsupport/knowledge-center/iam-ec2-resource-tags/">How do I create an IAM policy to control access to Amazon EC2 resources using tags?</a> in the AWS Knowledge Center. Tags are visible on the tagged dataset, but not on the ingestion resource.</p>
  ## 
  let valid = call_602012.validator(path, query, header, formData, body)
  let scheme = call_602012.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602012.url(scheme.get, call_602012.host, call_602012.base,
                         call_602012.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602012, url, valid)

proc call*(call_602013: Call_CreateIngestion_601999; AwsAccountId: string;
          DataSetId: string; IngestionId: string): Recallable =
  ## createIngestion
  ## <p>Creates and starts a new SPICE ingestion on a dataset</p> <p>Any ingestions operating on tagged datasets inherit the same tags automatically for use in access control. For an example, see <a href="https://aws.example.com/premiumsupport/knowledge-center/iam-ec2-resource-tags/">How do I create an IAM policy to control access to Amazon EC2 resources using tags?</a> in the AWS Knowledge Center. Tags are visible on the tagged dataset, but not on the ingestion resource.</p>
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSetId: string (required)
  ##            : The ID of the dataset used in the ingestion.
  ##   IngestionId: string (required)
  ##              : An ID for the ingestion.
  var path_602014 = newJObject()
  add(path_602014, "AwsAccountId", newJString(AwsAccountId))
  add(path_602014, "DataSetId", newJString(DataSetId))
  add(path_602014, "IngestionId", newJString(IngestionId))
  result = call_602013.call(path_602014, nil, nil, nil, nil)

var createIngestion* = Call_CreateIngestion_601999(name: "createIngestion",
    meth: HttpMethod.HttpPut, host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}/ingestions/{IngestionId}",
    validator: validate_CreateIngestion_602000, base: "/", url: url_CreateIngestion_602001,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeIngestion_601727 = ref object of OpenApiRestCall_601389
proc url_DescribeIngestion_601729(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeIngestion_601728(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  var valid_601855 = path.getOrDefault("AwsAccountId")
  valid_601855 = validateParameter(valid_601855, JString, required = true,
                                 default = nil)
  if valid_601855 != nil:
    section.add "AwsAccountId", valid_601855
  var valid_601856 = path.getOrDefault("DataSetId")
  valid_601856 = validateParameter(valid_601856, JString, required = true,
                                 default = nil)
  if valid_601856 != nil:
    section.add "DataSetId", valid_601856
  var valid_601857 = path.getOrDefault("IngestionId")
  valid_601857 = validateParameter(valid_601857, JString, required = true,
                                 default = nil)
  if valid_601857 != nil:
    section.add "IngestionId", valid_601857
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_601858 = header.getOrDefault("X-Amz-Signature")
  valid_601858 = validateParameter(valid_601858, JString, required = false,
                                 default = nil)
  if valid_601858 != nil:
    section.add "X-Amz-Signature", valid_601858
  var valid_601859 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601859 = validateParameter(valid_601859, JString, required = false,
                                 default = nil)
  if valid_601859 != nil:
    section.add "X-Amz-Content-Sha256", valid_601859
  var valid_601860 = header.getOrDefault("X-Amz-Date")
  valid_601860 = validateParameter(valid_601860, JString, required = false,
                                 default = nil)
  if valid_601860 != nil:
    section.add "X-Amz-Date", valid_601860
  var valid_601861 = header.getOrDefault("X-Amz-Credential")
  valid_601861 = validateParameter(valid_601861, JString, required = false,
                                 default = nil)
  if valid_601861 != nil:
    section.add "X-Amz-Credential", valid_601861
  var valid_601862 = header.getOrDefault("X-Amz-Security-Token")
  valid_601862 = validateParameter(valid_601862, JString, required = false,
                                 default = nil)
  if valid_601862 != nil:
    section.add "X-Amz-Security-Token", valid_601862
  var valid_601863 = header.getOrDefault("X-Amz-Algorithm")
  valid_601863 = validateParameter(valid_601863, JString, required = false,
                                 default = nil)
  if valid_601863 != nil:
    section.add "X-Amz-Algorithm", valid_601863
  var valid_601864 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601864 = validateParameter(valid_601864, JString, required = false,
                                 default = nil)
  if valid_601864 != nil:
    section.add "X-Amz-SignedHeaders", valid_601864
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601887: Call_DescribeIngestion_601727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a SPICE ingestion.
  ## 
  let valid = call_601887.validator(path, query, header, formData, body)
  let scheme = call_601887.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601887.url(scheme.get, call_601887.host, call_601887.base,
                         call_601887.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601887, url, valid)

proc call*(call_601958: Call_DescribeIngestion_601727; AwsAccountId: string;
          DataSetId: string; IngestionId: string): Recallable =
  ## describeIngestion
  ## Describes a SPICE ingestion.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSetId: string (required)
  ##            : The ID of the dataset used in the ingestion.
  ##   IngestionId: string (required)
  ##              : An ID for the ingestion.
  var path_601959 = newJObject()
  add(path_601959, "AwsAccountId", newJString(AwsAccountId))
  add(path_601959, "DataSetId", newJString(DataSetId))
  add(path_601959, "IngestionId", newJString(IngestionId))
  result = call_601958.call(path_601959, nil, nil, nil, nil)

var describeIngestion* = Call_DescribeIngestion_601727(name: "describeIngestion",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}/ingestions/{IngestionId}",
    validator: validate_DescribeIngestion_601728, base: "/",
    url: url_DescribeIngestion_601729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelIngestion_602015 = ref object of OpenApiRestCall_601389
proc url_CancelIngestion_602017(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CancelIngestion_602016(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
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
  var valid_602018 = path.getOrDefault("AwsAccountId")
  valid_602018 = validateParameter(valid_602018, JString, required = true,
                                 default = nil)
  if valid_602018 != nil:
    section.add "AwsAccountId", valid_602018
  var valid_602019 = path.getOrDefault("DataSetId")
  valid_602019 = validateParameter(valid_602019, JString, required = true,
                                 default = nil)
  if valid_602019 != nil:
    section.add "DataSetId", valid_602019
  var valid_602020 = path.getOrDefault("IngestionId")
  valid_602020 = validateParameter(valid_602020, JString, required = true,
                                 default = nil)
  if valid_602020 != nil:
    section.add "IngestionId", valid_602020
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602021 = header.getOrDefault("X-Amz-Signature")
  valid_602021 = validateParameter(valid_602021, JString, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "X-Amz-Signature", valid_602021
  var valid_602022 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602022 = validateParameter(valid_602022, JString, required = false,
                                 default = nil)
  if valid_602022 != nil:
    section.add "X-Amz-Content-Sha256", valid_602022
  var valid_602023 = header.getOrDefault("X-Amz-Date")
  valid_602023 = validateParameter(valid_602023, JString, required = false,
                                 default = nil)
  if valid_602023 != nil:
    section.add "X-Amz-Date", valid_602023
  var valid_602024 = header.getOrDefault("X-Amz-Credential")
  valid_602024 = validateParameter(valid_602024, JString, required = false,
                                 default = nil)
  if valid_602024 != nil:
    section.add "X-Amz-Credential", valid_602024
  var valid_602025 = header.getOrDefault("X-Amz-Security-Token")
  valid_602025 = validateParameter(valid_602025, JString, required = false,
                                 default = nil)
  if valid_602025 != nil:
    section.add "X-Amz-Security-Token", valid_602025
  var valid_602026 = header.getOrDefault("X-Amz-Algorithm")
  valid_602026 = validateParameter(valid_602026, JString, required = false,
                                 default = nil)
  if valid_602026 != nil:
    section.add "X-Amz-Algorithm", valid_602026
  var valid_602027 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602027 = validateParameter(valid_602027, JString, required = false,
                                 default = nil)
  if valid_602027 != nil:
    section.add "X-Amz-SignedHeaders", valid_602027
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602028: Call_CancelIngestion_602015; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels an ongoing ingestion of data into SPICE.
  ## 
  let valid = call_602028.validator(path, query, header, formData, body)
  let scheme = call_602028.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602028.url(scheme.get, call_602028.host, call_602028.base,
                         call_602028.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602028, url, valid)

proc call*(call_602029: Call_CancelIngestion_602015; AwsAccountId: string;
          DataSetId: string; IngestionId: string): Recallable =
  ## cancelIngestion
  ## Cancels an ongoing ingestion of data into SPICE.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSetId: string (required)
  ##            : The ID of the dataset used in the ingestion.
  ##   IngestionId: string (required)
  ##              : An ID for the ingestion.
  var path_602030 = newJObject()
  add(path_602030, "AwsAccountId", newJString(AwsAccountId))
  add(path_602030, "DataSetId", newJString(DataSetId))
  add(path_602030, "IngestionId", newJString(IngestionId))
  result = call_602029.call(path_602030, nil, nil, nil, nil)

var cancelIngestion* = Call_CancelIngestion_602015(name: "cancelIngestion",
    meth: HttpMethod.HttpDelete, host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}/ingestions/{IngestionId}",
    validator: validate_CancelIngestion_602016, base: "/", url: url_CancelIngestion_602017,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDashboard_602049 = ref object of OpenApiRestCall_601389
proc url_UpdateDashboard_602051(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDashboard_602050(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
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
  var valid_602052 = path.getOrDefault("AwsAccountId")
  valid_602052 = validateParameter(valid_602052, JString, required = true,
                                 default = nil)
  if valid_602052 != nil:
    section.add "AwsAccountId", valid_602052
  var valid_602053 = path.getOrDefault("DashboardId")
  valid_602053 = validateParameter(valid_602053, JString, required = true,
                                 default = nil)
  if valid_602053 != nil:
    section.add "DashboardId", valid_602053
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602054 = header.getOrDefault("X-Amz-Signature")
  valid_602054 = validateParameter(valid_602054, JString, required = false,
                                 default = nil)
  if valid_602054 != nil:
    section.add "X-Amz-Signature", valid_602054
  var valid_602055 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602055 = validateParameter(valid_602055, JString, required = false,
                                 default = nil)
  if valid_602055 != nil:
    section.add "X-Amz-Content-Sha256", valid_602055
  var valid_602056 = header.getOrDefault("X-Amz-Date")
  valid_602056 = validateParameter(valid_602056, JString, required = false,
                                 default = nil)
  if valid_602056 != nil:
    section.add "X-Amz-Date", valid_602056
  var valid_602057 = header.getOrDefault("X-Amz-Credential")
  valid_602057 = validateParameter(valid_602057, JString, required = false,
                                 default = nil)
  if valid_602057 != nil:
    section.add "X-Amz-Credential", valid_602057
  var valid_602058 = header.getOrDefault("X-Amz-Security-Token")
  valid_602058 = validateParameter(valid_602058, JString, required = false,
                                 default = nil)
  if valid_602058 != nil:
    section.add "X-Amz-Security-Token", valid_602058
  var valid_602059 = header.getOrDefault("X-Amz-Algorithm")
  valid_602059 = validateParameter(valid_602059, JString, required = false,
                                 default = nil)
  if valid_602059 != nil:
    section.add "X-Amz-Algorithm", valid_602059
  var valid_602060 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602060 = validateParameter(valid_602060, JString, required = false,
                                 default = nil)
  if valid_602060 != nil:
    section.add "X-Amz-SignedHeaders", valid_602060
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602062: Call_UpdateDashboard_602049; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a dashboard in an AWS account.
  ## 
  let valid = call_602062.validator(path, query, header, formData, body)
  let scheme = call_602062.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602062.url(scheme.get, call_602062.host, call_602062.base,
                         call_602062.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602062, url, valid)

proc call*(call_602063: Call_UpdateDashboard_602049; AwsAccountId: string;
          body: JsonNode; DashboardId: string): Recallable =
  ## updateDashboard
  ## Updates a dashboard in an AWS account.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the dashboard that you're updating.
  ##   body: JObject (required)
  ##   DashboardId: string (required)
  ##              : The ID for the dashboard.
  var path_602064 = newJObject()
  var body_602065 = newJObject()
  add(path_602064, "AwsAccountId", newJString(AwsAccountId))
  if body != nil:
    body_602065 = body
  add(path_602064, "DashboardId", newJString(DashboardId))
  result = call_602063.call(path_602064, nil, nil, nil, body_602065)

var updateDashboard* = Call_UpdateDashboard_602049(name: "updateDashboard",
    meth: HttpMethod.HttpPut, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}",
    validator: validate_UpdateDashboard_602050, base: "/", url: url_UpdateDashboard_602051,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDashboard_602066 = ref object of OpenApiRestCall_601389
proc url_CreateDashboard_602068(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateDashboard_602067(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
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
  var valid_602069 = path.getOrDefault("AwsAccountId")
  valid_602069 = validateParameter(valid_602069, JString, required = true,
                                 default = nil)
  if valid_602069 != nil:
    section.add "AwsAccountId", valid_602069
  var valid_602070 = path.getOrDefault("DashboardId")
  valid_602070 = validateParameter(valid_602070, JString, required = true,
                                 default = nil)
  if valid_602070 != nil:
    section.add "DashboardId", valid_602070
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602071 = header.getOrDefault("X-Amz-Signature")
  valid_602071 = validateParameter(valid_602071, JString, required = false,
                                 default = nil)
  if valid_602071 != nil:
    section.add "X-Amz-Signature", valid_602071
  var valid_602072 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602072 = validateParameter(valid_602072, JString, required = false,
                                 default = nil)
  if valid_602072 != nil:
    section.add "X-Amz-Content-Sha256", valid_602072
  var valid_602073 = header.getOrDefault("X-Amz-Date")
  valid_602073 = validateParameter(valid_602073, JString, required = false,
                                 default = nil)
  if valid_602073 != nil:
    section.add "X-Amz-Date", valid_602073
  var valid_602074 = header.getOrDefault("X-Amz-Credential")
  valid_602074 = validateParameter(valid_602074, JString, required = false,
                                 default = nil)
  if valid_602074 != nil:
    section.add "X-Amz-Credential", valid_602074
  var valid_602075 = header.getOrDefault("X-Amz-Security-Token")
  valid_602075 = validateParameter(valid_602075, JString, required = false,
                                 default = nil)
  if valid_602075 != nil:
    section.add "X-Amz-Security-Token", valid_602075
  var valid_602076 = header.getOrDefault("X-Amz-Algorithm")
  valid_602076 = validateParameter(valid_602076, JString, required = false,
                                 default = nil)
  if valid_602076 != nil:
    section.add "X-Amz-Algorithm", valid_602076
  var valid_602077 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602077 = validateParameter(valid_602077, JString, required = false,
                                 default = nil)
  if valid_602077 != nil:
    section.add "X-Amz-SignedHeaders", valid_602077
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602079: Call_CreateDashboard_602066; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a dashboard from a template. To first create a template, see the CreateTemplate API operation.</p> <p>A dashboard is an entity in QuickSight that identifies QuickSight reports, created from analyses. You can share QuickSight dashboards. With the right permissions, you can create scheduled email reports from them. The <code>CreateDashboard</code>, <code>DescribeDashboard</code>, and <code>ListDashboardsByUser</code> API operations act on the dashboard entity. If you have the correct permissions, you can create a dashboard from a template that exists in a different AWS account.</p>
  ## 
  let valid = call_602079.validator(path, query, header, formData, body)
  let scheme = call_602079.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602079.url(scheme.get, call_602079.host, call_602079.base,
                         call_602079.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602079, url, valid)

proc call*(call_602080: Call_CreateDashboard_602066; AwsAccountId: string;
          body: JsonNode; DashboardId: string): Recallable =
  ## createDashboard
  ## <p>Creates a dashboard from a template. To first create a template, see the CreateTemplate API operation.</p> <p>A dashboard is an entity in QuickSight that identifies QuickSight reports, created from analyses. You can share QuickSight dashboards. With the right permissions, you can create scheduled email reports from them. The <code>CreateDashboard</code>, <code>DescribeDashboard</code>, and <code>ListDashboardsByUser</code> API operations act on the dashboard entity. If you have the correct permissions, you can create a dashboard from a template that exists in a different AWS account.</p>
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account where you want to create the dashboard.
  ##   body: JObject (required)
  ##   DashboardId: string (required)
  ##              : The ID for the dashboard, also added to the IAM policy.
  var path_602081 = newJObject()
  var body_602082 = newJObject()
  add(path_602081, "AwsAccountId", newJString(AwsAccountId))
  if body != nil:
    body_602082 = body
  add(path_602081, "DashboardId", newJString(DashboardId))
  result = call_602080.call(path_602081, nil, nil, nil, body_602082)

var createDashboard* = Call_CreateDashboard_602066(name: "createDashboard",
    meth: HttpMethod.HttpPost, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}",
    validator: validate_CreateDashboard_602067, base: "/", url: url_CreateDashboard_602068,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDashboard_602031 = ref object of OpenApiRestCall_601389
proc url_DescribeDashboard_602033(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeDashboard_602032(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  var valid_602034 = path.getOrDefault("AwsAccountId")
  valid_602034 = validateParameter(valid_602034, JString, required = true,
                                 default = nil)
  if valid_602034 != nil:
    section.add "AwsAccountId", valid_602034
  var valid_602035 = path.getOrDefault("DashboardId")
  valid_602035 = validateParameter(valid_602035, JString, required = true,
                                 default = nil)
  if valid_602035 != nil:
    section.add "DashboardId", valid_602035
  result.add "path", section
  ## parameters in `query` object:
  ##   version-number: JInt
  ##                 : The version number for the dashboard. If a version number isn't passed, the latest published dashboard version is described. 
  ##   alias-name: JString
  ##             : The alias name.
  section = newJObject()
  var valid_602036 = query.getOrDefault("version-number")
  valid_602036 = validateParameter(valid_602036, JInt, required = false, default = nil)
  if valid_602036 != nil:
    section.add "version-number", valid_602036
  var valid_602037 = query.getOrDefault("alias-name")
  valid_602037 = validateParameter(valid_602037, JString, required = false,
                                 default = nil)
  if valid_602037 != nil:
    section.add "alias-name", valid_602037
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602038 = header.getOrDefault("X-Amz-Signature")
  valid_602038 = validateParameter(valid_602038, JString, required = false,
                                 default = nil)
  if valid_602038 != nil:
    section.add "X-Amz-Signature", valid_602038
  var valid_602039 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602039 = validateParameter(valid_602039, JString, required = false,
                                 default = nil)
  if valid_602039 != nil:
    section.add "X-Amz-Content-Sha256", valid_602039
  var valid_602040 = header.getOrDefault("X-Amz-Date")
  valid_602040 = validateParameter(valid_602040, JString, required = false,
                                 default = nil)
  if valid_602040 != nil:
    section.add "X-Amz-Date", valid_602040
  var valid_602041 = header.getOrDefault("X-Amz-Credential")
  valid_602041 = validateParameter(valid_602041, JString, required = false,
                                 default = nil)
  if valid_602041 != nil:
    section.add "X-Amz-Credential", valid_602041
  var valid_602042 = header.getOrDefault("X-Amz-Security-Token")
  valid_602042 = validateParameter(valid_602042, JString, required = false,
                                 default = nil)
  if valid_602042 != nil:
    section.add "X-Amz-Security-Token", valid_602042
  var valid_602043 = header.getOrDefault("X-Amz-Algorithm")
  valid_602043 = validateParameter(valid_602043, JString, required = false,
                                 default = nil)
  if valid_602043 != nil:
    section.add "X-Amz-Algorithm", valid_602043
  var valid_602044 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602044 = validateParameter(valid_602044, JString, required = false,
                                 default = nil)
  if valid_602044 != nil:
    section.add "X-Amz-SignedHeaders", valid_602044
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602045: Call_DescribeDashboard_602031; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides a summary for a dashboard.
  ## 
  let valid = call_602045.validator(path, query, header, formData, body)
  let scheme = call_602045.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602045.url(scheme.get, call_602045.host, call_602045.base,
                         call_602045.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602045, url, valid)

proc call*(call_602046: Call_DescribeDashboard_602031; AwsAccountId: string;
          DashboardId: string; versionNumber: int = 0; aliasName: string = ""): Recallable =
  ## describeDashboard
  ## Provides a summary for a dashboard.
  ##   versionNumber: int
  ##                : The version number for the dashboard. If a version number isn't passed, the latest published dashboard version is described. 
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the dashboard that you're describing.
  ##   aliasName: string
  ##            : The alias name.
  ##   DashboardId: string (required)
  ##              : The ID for the dashboard.
  var path_602047 = newJObject()
  var query_602048 = newJObject()
  add(query_602048, "version-number", newJInt(versionNumber))
  add(path_602047, "AwsAccountId", newJString(AwsAccountId))
  add(query_602048, "alias-name", newJString(aliasName))
  add(path_602047, "DashboardId", newJString(DashboardId))
  result = call_602046.call(path_602047, query_602048, nil, nil, nil)

var describeDashboard* = Call_DescribeDashboard_602031(name: "describeDashboard",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}",
    validator: validate_DescribeDashboard_602032, base: "/",
    url: url_DescribeDashboard_602033, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDashboard_602083 = ref object of OpenApiRestCall_601389
proc url_DeleteDashboard_602085(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDashboard_602084(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
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
  var valid_602086 = path.getOrDefault("AwsAccountId")
  valid_602086 = validateParameter(valid_602086, JString, required = true,
                                 default = nil)
  if valid_602086 != nil:
    section.add "AwsAccountId", valid_602086
  var valid_602087 = path.getOrDefault("DashboardId")
  valid_602087 = validateParameter(valid_602087, JString, required = true,
                                 default = nil)
  if valid_602087 != nil:
    section.add "DashboardId", valid_602087
  result.add "path", section
  ## parameters in `query` object:
  ##   version-number: JInt
  ##                 : The version number of the dashboard. If the version number property is provided, only the specified version of the dashboard is deleted.
  section = newJObject()
  var valid_602088 = query.getOrDefault("version-number")
  valid_602088 = validateParameter(valid_602088, JInt, required = false, default = nil)
  if valid_602088 != nil:
    section.add "version-number", valid_602088
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602089 = header.getOrDefault("X-Amz-Signature")
  valid_602089 = validateParameter(valid_602089, JString, required = false,
                                 default = nil)
  if valid_602089 != nil:
    section.add "X-Amz-Signature", valid_602089
  var valid_602090 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602090 = validateParameter(valid_602090, JString, required = false,
                                 default = nil)
  if valid_602090 != nil:
    section.add "X-Amz-Content-Sha256", valid_602090
  var valid_602091 = header.getOrDefault("X-Amz-Date")
  valid_602091 = validateParameter(valid_602091, JString, required = false,
                                 default = nil)
  if valid_602091 != nil:
    section.add "X-Amz-Date", valid_602091
  var valid_602092 = header.getOrDefault("X-Amz-Credential")
  valid_602092 = validateParameter(valid_602092, JString, required = false,
                                 default = nil)
  if valid_602092 != nil:
    section.add "X-Amz-Credential", valid_602092
  var valid_602093 = header.getOrDefault("X-Amz-Security-Token")
  valid_602093 = validateParameter(valid_602093, JString, required = false,
                                 default = nil)
  if valid_602093 != nil:
    section.add "X-Amz-Security-Token", valid_602093
  var valid_602094 = header.getOrDefault("X-Amz-Algorithm")
  valid_602094 = validateParameter(valid_602094, JString, required = false,
                                 default = nil)
  if valid_602094 != nil:
    section.add "X-Amz-Algorithm", valid_602094
  var valid_602095 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602095 = validateParameter(valid_602095, JString, required = false,
                                 default = nil)
  if valid_602095 != nil:
    section.add "X-Amz-SignedHeaders", valid_602095
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602096: Call_DeleteDashboard_602083; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a dashboard.
  ## 
  let valid = call_602096.validator(path, query, header, formData, body)
  let scheme = call_602096.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602096.url(scheme.get, call_602096.host, call_602096.base,
                         call_602096.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602096, url, valid)

proc call*(call_602097: Call_DeleteDashboard_602083; AwsAccountId: string;
          DashboardId: string; versionNumber: int = 0): Recallable =
  ## deleteDashboard
  ## Deletes a dashboard.
  ##   versionNumber: int
  ##                : The version number of the dashboard. If the version number property is provided, only the specified version of the dashboard is deleted.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the dashboard that you're deleting.
  ##   DashboardId: string (required)
  ##              : The ID for the dashboard.
  var path_602098 = newJObject()
  var query_602099 = newJObject()
  add(query_602099, "version-number", newJInt(versionNumber))
  add(path_602098, "AwsAccountId", newJString(AwsAccountId))
  add(path_602098, "DashboardId", newJString(DashboardId))
  result = call_602097.call(path_602098, query_602099, nil, nil, nil)

var deleteDashboard* = Call_DeleteDashboard_602083(name: "deleteDashboard",
    meth: HttpMethod.HttpDelete, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}",
    validator: validate_DeleteDashboard_602084, base: "/", url: url_DeleteDashboard_602085,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataSet_602119 = ref object of OpenApiRestCall_601389
proc url_CreateDataSet_602121(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateDataSet_602120(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_602122 = path.getOrDefault("AwsAccountId")
  valid_602122 = validateParameter(valid_602122, JString, required = true,
                                 default = nil)
  if valid_602122 != nil:
    section.add "AwsAccountId", valid_602122
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602123 = header.getOrDefault("X-Amz-Signature")
  valid_602123 = validateParameter(valid_602123, JString, required = false,
                                 default = nil)
  if valid_602123 != nil:
    section.add "X-Amz-Signature", valid_602123
  var valid_602124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602124 = validateParameter(valid_602124, JString, required = false,
                                 default = nil)
  if valid_602124 != nil:
    section.add "X-Amz-Content-Sha256", valid_602124
  var valid_602125 = header.getOrDefault("X-Amz-Date")
  valid_602125 = validateParameter(valid_602125, JString, required = false,
                                 default = nil)
  if valid_602125 != nil:
    section.add "X-Amz-Date", valid_602125
  var valid_602126 = header.getOrDefault("X-Amz-Credential")
  valid_602126 = validateParameter(valid_602126, JString, required = false,
                                 default = nil)
  if valid_602126 != nil:
    section.add "X-Amz-Credential", valid_602126
  var valid_602127 = header.getOrDefault("X-Amz-Security-Token")
  valid_602127 = validateParameter(valid_602127, JString, required = false,
                                 default = nil)
  if valid_602127 != nil:
    section.add "X-Amz-Security-Token", valid_602127
  var valid_602128 = header.getOrDefault("X-Amz-Algorithm")
  valid_602128 = validateParameter(valid_602128, JString, required = false,
                                 default = nil)
  if valid_602128 != nil:
    section.add "X-Amz-Algorithm", valid_602128
  var valid_602129 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602129 = validateParameter(valid_602129, JString, required = false,
                                 default = nil)
  if valid_602129 != nil:
    section.add "X-Amz-SignedHeaders", valid_602129
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602131: Call_CreateDataSet_602119; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a dataset.
  ## 
  let valid = call_602131.validator(path, query, header, formData, body)
  let scheme = call_602131.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602131.url(scheme.get, call_602131.host, call_602131.base,
                         call_602131.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602131, url, valid)

proc call*(call_602132: Call_CreateDataSet_602119; AwsAccountId: string;
          body: JsonNode): Recallable =
  ## createDataSet
  ## Creates a dataset.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   body: JObject (required)
  var path_602133 = newJObject()
  var body_602134 = newJObject()
  add(path_602133, "AwsAccountId", newJString(AwsAccountId))
  if body != nil:
    body_602134 = body
  result = call_602132.call(path_602133, nil, nil, nil, body_602134)

var createDataSet* = Call_CreateDataSet_602119(name: "createDataSet",
    meth: HttpMethod.HttpPost, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sets",
    validator: validate_CreateDataSet_602120, base: "/", url: url_CreateDataSet_602121,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDataSets_602100 = ref object of OpenApiRestCall_601389
proc url_ListDataSets_602102(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListDataSets_602101(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_602103 = path.getOrDefault("AwsAccountId")
  valid_602103 = validateParameter(valid_602103, JString, required = true,
                                 default = nil)
  if valid_602103 != nil:
    section.add "AwsAccountId", valid_602103
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   max-results: JInt
  ##              : The maximum number of results to be returned per request.
  ##   next-token: JString
  ##             : The token for the next set of results, or null if there are no more results.
  section = newJObject()
  var valid_602104 = query.getOrDefault("MaxResults")
  valid_602104 = validateParameter(valid_602104, JString, required = false,
                                 default = nil)
  if valid_602104 != nil:
    section.add "MaxResults", valid_602104
  var valid_602105 = query.getOrDefault("NextToken")
  valid_602105 = validateParameter(valid_602105, JString, required = false,
                                 default = nil)
  if valid_602105 != nil:
    section.add "NextToken", valid_602105
  var valid_602106 = query.getOrDefault("max-results")
  valid_602106 = validateParameter(valid_602106, JInt, required = false, default = nil)
  if valid_602106 != nil:
    section.add "max-results", valid_602106
  var valid_602107 = query.getOrDefault("next-token")
  valid_602107 = validateParameter(valid_602107, JString, required = false,
                                 default = nil)
  if valid_602107 != nil:
    section.add "next-token", valid_602107
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602108 = header.getOrDefault("X-Amz-Signature")
  valid_602108 = validateParameter(valid_602108, JString, required = false,
                                 default = nil)
  if valid_602108 != nil:
    section.add "X-Amz-Signature", valid_602108
  var valid_602109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602109 = validateParameter(valid_602109, JString, required = false,
                                 default = nil)
  if valid_602109 != nil:
    section.add "X-Amz-Content-Sha256", valid_602109
  var valid_602110 = header.getOrDefault("X-Amz-Date")
  valid_602110 = validateParameter(valid_602110, JString, required = false,
                                 default = nil)
  if valid_602110 != nil:
    section.add "X-Amz-Date", valid_602110
  var valid_602111 = header.getOrDefault("X-Amz-Credential")
  valid_602111 = validateParameter(valid_602111, JString, required = false,
                                 default = nil)
  if valid_602111 != nil:
    section.add "X-Amz-Credential", valid_602111
  var valid_602112 = header.getOrDefault("X-Amz-Security-Token")
  valid_602112 = validateParameter(valid_602112, JString, required = false,
                                 default = nil)
  if valid_602112 != nil:
    section.add "X-Amz-Security-Token", valid_602112
  var valid_602113 = header.getOrDefault("X-Amz-Algorithm")
  valid_602113 = validateParameter(valid_602113, JString, required = false,
                                 default = nil)
  if valid_602113 != nil:
    section.add "X-Amz-Algorithm", valid_602113
  var valid_602114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602114 = validateParameter(valid_602114, JString, required = false,
                                 default = nil)
  if valid_602114 != nil:
    section.add "X-Amz-SignedHeaders", valid_602114
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602115: Call_ListDataSets_602100; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists all of the datasets belonging to the current AWS account in an AWS Region.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:dataset/*</code>.</p>
  ## 
  let valid = call_602115.validator(path, query, header, formData, body)
  let scheme = call_602115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602115.url(scheme.get, call_602115.host, call_602115.base,
                         call_602115.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602115, url, valid)

proc call*(call_602116: Call_ListDataSets_602100; AwsAccountId: string;
          MaxResults: string = ""; NextToken: string = ""; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listDataSets
  ## <p>Lists all of the datasets belonging to the current AWS account in an AWS Region.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:dataset/*</code>.</p>
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results to be returned per request.
  ##   nextToken: string
  ##            : The token for the next set of results, or null if there are no more results.
  var path_602117 = newJObject()
  var query_602118 = newJObject()
  add(path_602117, "AwsAccountId", newJString(AwsAccountId))
  add(query_602118, "MaxResults", newJString(MaxResults))
  add(query_602118, "NextToken", newJString(NextToken))
  add(query_602118, "max-results", newJInt(maxResults))
  add(query_602118, "next-token", newJString(nextToken))
  result = call_602116.call(path_602117, query_602118, nil, nil, nil)

var listDataSets* = Call_ListDataSets_602100(name: "listDataSets",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sets", validator: validate_ListDataSets_602101,
    base: "/", url: url_ListDataSets_602102, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataSource_602154 = ref object of OpenApiRestCall_601389
proc url_CreateDataSource_602156(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateDataSource_602155(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
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
  var valid_602157 = path.getOrDefault("AwsAccountId")
  valid_602157 = validateParameter(valid_602157, JString, required = true,
                                 default = nil)
  if valid_602157 != nil:
    section.add "AwsAccountId", valid_602157
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602158 = header.getOrDefault("X-Amz-Signature")
  valid_602158 = validateParameter(valid_602158, JString, required = false,
                                 default = nil)
  if valid_602158 != nil:
    section.add "X-Amz-Signature", valid_602158
  var valid_602159 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602159 = validateParameter(valid_602159, JString, required = false,
                                 default = nil)
  if valid_602159 != nil:
    section.add "X-Amz-Content-Sha256", valid_602159
  var valid_602160 = header.getOrDefault("X-Amz-Date")
  valid_602160 = validateParameter(valid_602160, JString, required = false,
                                 default = nil)
  if valid_602160 != nil:
    section.add "X-Amz-Date", valid_602160
  var valid_602161 = header.getOrDefault("X-Amz-Credential")
  valid_602161 = validateParameter(valid_602161, JString, required = false,
                                 default = nil)
  if valid_602161 != nil:
    section.add "X-Amz-Credential", valid_602161
  var valid_602162 = header.getOrDefault("X-Amz-Security-Token")
  valid_602162 = validateParameter(valid_602162, JString, required = false,
                                 default = nil)
  if valid_602162 != nil:
    section.add "X-Amz-Security-Token", valid_602162
  var valid_602163 = header.getOrDefault("X-Amz-Algorithm")
  valid_602163 = validateParameter(valid_602163, JString, required = false,
                                 default = nil)
  if valid_602163 != nil:
    section.add "X-Amz-Algorithm", valid_602163
  var valid_602164 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602164 = validateParameter(valid_602164, JString, required = false,
                                 default = nil)
  if valid_602164 != nil:
    section.add "X-Amz-SignedHeaders", valid_602164
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602166: Call_CreateDataSource_602154; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a data source.
  ## 
  let valid = call_602166.validator(path, query, header, formData, body)
  let scheme = call_602166.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602166.url(scheme.get, call_602166.host, call_602166.base,
                         call_602166.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602166, url, valid)

proc call*(call_602167: Call_CreateDataSource_602154; AwsAccountId: string;
          body: JsonNode): Recallable =
  ## createDataSource
  ## Creates a data source.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   body: JObject (required)
  var path_602168 = newJObject()
  var body_602169 = newJObject()
  add(path_602168, "AwsAccountId", newJString(AwsAccountId))
  if body != nil:
    body_602169 = body
  result = call_602167.call(path_602168, nil, nil, nil, body_602169)

var createDataSource* = Call_CreateDataSource_602154(name: "createDataSource",
    meth: HttpMethod.HttpPost, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sources",
    validator: validate_CreateDataSource_602155, base: "/",
    url: url_CreateDataSource_602156, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDataSources_602135 = ref object of OpenApiRestCall_601389
proc url_ListDataSources_602137(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListDataSources_602136(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
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
  var valid_602138 = path.getOrDefault("AwsAccountId")
  valid_602138 = validateParameter(valid_602138, JString, required = true,
                                 default = nil)
  if valid_602138 != nil:
    section.add "AwsAccountId", valid_602138
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   max-results: JInt
  ##              : The maximum number of results to be returned per request.
  ##   next-token: JString
  ##             : The token for the next set of results, or null if there are no more results.
  section = newJObject()
  var valid_602139 = query.getOrDefault("MaxResults")
  valid_602139 = validateParameter(valid_602139, JString, required = false,
                                 default = nil)
  if valid_602139 != nil:
    section.add "MaxResults", valid_602139
  var valid_602140 = query.getOrDefault("NextToken")
  valid_602140 = validateParameter(valid_602140, JString, required = false,
                                 default = nil)
  if valid_602140 != nil:
    section.add "NextToken", valid_602140
  var valid_602141 = query.getOrDefault("max-results")
  valid_602141 = validateParameter(valid_602141, JInt, required = false, default = nil)
  if valid_602141 != nil:
    section.add "max-results", valid_602141
  var valid_602142 = query.getOrDefault("next-token")
  valid_602142 = validateParameter(valid_602142, JString, required = false,
                                 default = nil)
  if valid_602142 != nil:
    section.add "next-token", valid_602142
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602143 = header.getOrDefault("X-Amz-Signature")
  valid_602143 = validateParameter(valid_602143, JString, required = false,
                                 default = nil)
  if valid_602143 != nil:
    section.add "X-Amz-Signature", valid_602143
  var valid_602144 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602144 = validateParameter(valid_602144, JString, required = false,
                                 default = nil)
  if valid_602144 != nil:
    section.add "X-Amz-Content-Sha256", valid_602144
  var valid_602145 = header.getOrDefault("X-Amz-Date")
  valid_602145 = validateParameter(valid_602145, JString, required = false,
                                 default = nil)
  if valid_602145 != nil:
    section.add "X-Amz-Date", valid_602145
  var valid_602146 = header.getOrDefault("X-Amz-Credential")
  valid_602146 = validateParameter(valid_602146, JString, required = false,
                                 default = nil)
  if valid_602146 != nil:
    section.add "X-Amz-Credential", valid_602146
  var valid_602147 = header.getOrDefault("X-Amz-Security-Token")
  valid_602147 = validateParameter(valid_602147, JString, required = false,
                                 default = nil)
  if valid_602147 != nil:
    section.add "X-Amz-Security-Token", valid_602147
  var valid_602148 = header.getOrDefault("X-Amz-Algorithm")
  valid_602148 = validateParameter(valid_602148, JString, required = false,
                                 default = nil)
  if valid_602148 != nil:
    section.add "X-Amz-Algorithm", valid_602148
  var valid_602149 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602149 = validateParameter(valid_602149, JString, required = false,
                                 default = nil)
  if valid_602149 != nil:
    section.add "X-Amz-SignedHeaders", valid_602149
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602150: Call_ListDataSources_602135; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists data sources in current AWS Region that belong to this AWS account.
  ## 
  let valid = call_602150.validator(path, query, header, formData, body)
  let scheme = call_602150.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602150.url(scheme.get, call_602150.host, call_602150.base,
                         call_602150.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602150, url, valid)

proc call*(call_602151: Call_ListDataSources_602135; AwsAccountId: string;
          MaxResults: string = ""; NextToken: string = ""; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listDataSources
  ## Lists data sources in current AWS Region that belong to this AWS account.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results to be returned per request.
  ##   nextToken: string
  ##            : The token for the next set of results, or null if there are no more results.
  var path_602152 = newJObject()
  var query_602153 = newJObject()
  add(path_602152, "AwsAccountId", newJString(AwsAccountId))
  add(query_602153, "MaxResults", newJString(MaxResults))
  add(query_602153, "NextToken", newJString(NextToken))
  add(query_602153, "max-results", newJInt(maxResults))
  add(query_602153, "next-token", newJString(nextToken))
  result = call_602151.call(path_602152, query_602153, nil, nil, nil)

var listDataSources* = Call_ListDataSources_602135(name: "listDataSources",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sources",
    validator: validate_ListDataSources_602136, base: "/", url: url_ListDataSources_602137,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGroup_602188 = ref object of OpenApiRestCall_601389
proc url_CreateGroup_602190(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateGroup_602189(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_602191 = path.getOrDefault("AwsAccountId")
  valid_602191 = validateParameter(valid_602191, JString, required = true,
                                 default = nil)
  if valid_602191 != nil:
    section.add "AwsAccountId", valid_602191
  var valid_602192 = path.getOrDefault("Namespace")
  valid_602192 = validateParameter(valid_602192, JString, required = true,
                                 default = nil)
  if valid_602192 != nil:
    section.add "Namespace", valid_602192
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602193 = header.getOrDefault("X-Amz-Signature")
  valid_602193 = validateParameter(valid_602193, JString, required = false,
                                 default = nil)
  if valid_602193 != nil:
    section.add "X-Amz-Signature", valid_602193
  var valid_602194 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602194 = validateParameter(valid_602194, JString, required = false,
                                 default = nil)
  if valid_602194 != nil:
    section.add "X-Amz-Content-Sha256", valid_602194
  var valid_602195 = header.getOrDefault("X-Amz-Date")
  valid_602195 = validateParameter(valid_602195, JString, required = false,
                                 default = nil)
  if valid_602195 != nil:
    section.add "X-Amz-Date", valid_602195
  var valid_602196 = header.getOrDefault("X-Amz-Credential")
  valid_602196 = validateParameter(valid_602196, JString, required = false,
                                 default = nil)
  if valid_602196 != nil:
    section.add "X-Amz-Credential", valid_602196
  var valid_602197 = header.getOrDefault("X-Amz-Security-Token")
  valid_602197 = validateParameter(valid_602197, JString, required = false,
                                 default = nil)
  if valid_602197 != nil:
    section.add "X-Amz-Security-Token", valid_602197
  var valid_602198 = header.getOrDefault("X-Amz-Algorithm")
  valid_602198 = validateParameter(valid_602198, JString, required = false,
                                 default = nil)
  if valid_602198 != nil:
    section.add "X-Amz-Algorithm", valid_602198
  var valid_602199 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602199 = validateParameter(valid_602199, JString, required = false,
                                 default = nil)
  if valid_602199 != nil:
    section.add "X-Amz-SignedHeaders", valid_602199
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602201: Call_CreateGroup_602188; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Amazon QuickSight group.</p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;relevant-aws-account-id&gt;</i>:group/default/<i>&lt;group-name&gt;</i> </code>.</p> <p>The response is a group object.</p>
  ## 
  let valid = call_602201.validator(path, query, header, formData, body)
  let scheme = call_602201.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602201.url(scheme.get, call_602201.host, call_602201.base,
                         call_602201.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602201, url, valid)

proc call*(call_602202: Call_CreateGroup_602188; AwsAccountId: string;
          Namespace: string; body: JsonNode): Recallable =
  ## createGroup
  ## <p>Creates an Amazon QuickSight group.</p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;relevant-aws-account-id&gt;</i>:group/default/<i>&lt;group-name&gt;</i> </code>.</p> <p>The response is a group object.</p>
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   body: JObject (required)
  var path_602203 = newJObject()
  var body_602204 = newJObject()
  add(path_602203, "AwsAccountId", newJString(AwsAccountId))
  add(path_602203, "Namespace", newJString(Namespace))
  if body != nil:
    body_602204 = body
  result = call_602202.call(path_602203, nil, nil, nil, body_602204)

var createGroup* = Call_CreateGroup_602188(name: "createGroup",
                                        meth: HttpMethod.HttpPost,
                                        host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups",
                                        validator: validate_CreateGroup_602189,
                                        base: "/", url: url_CreateGroup_602190,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroups_602170 = ref object of OpenApiRestCall_601389
proc url_ListGroups_602172(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListGroups_602171(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_602173 = path.getOrDefault("AwsAccountId")
  valid_602173 = validateParameter(valid_602173, JString, required = true,
                                 default = nil)
  if valid_602173 != nil:
    section.add "AwsAccountId", valid_602173
  var valid_602174 = path.getOrDefault("Namespace")
  valid_602174 = validateParameter(valid_602174, JString, required = true,
                                 default = nil)
  if valid_602174 != nil:
    section.add "Namespace", valid_602174
  result.add "path", section
  ## parameters in `query` object:
  ##   max-results: JInt
  ##              : The maximum number of results to return.
  ##   next-token: JString
  ##             : A pagination token that can be used in a subsequent request.
  section = newJObject()
  var valid_602175 = query.getOrDefault("max-results")
  valid_602175 = validateParameter(valid_602175, JInt, required = false, default = nil)
  if valid_602175 != nil:
    section.add "max-results", valid_602175
  var valid_602176 = query.getOrDefault("next-token")
  valid_602176 = validateParameter(valid_602176, JString, required = false,
                                 default = nil)
  if valid_602176 != nil:
    section.add "next-token", valid_602176
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602177 = header.getOrDefault("X-Amz-Signature")
  valid_602177 = validateParameter(valid_602177, JString, required = false,
                                 default = nil)
  if valid_602177 != nil:
    section.add "X-Amz-Signature", valid_602177
  var valid_602178 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602178 = validateParameter(valid_602178, JString, required = false,
                                 default = nil)
  if valid_602178 != nil:
    section.add "X-Amz-Content-Sha256", valid_602178
  var valid_602179 = header.getOrDefault("X-Amz-Date")
  valid_602179 = validateParameter(valid_602179, JString, required = false,
                                 default = nil)
  if valid_602179 != nil:
    section.add "X-Amz-Date", valid_602179
  var valid_602180 = header.getOrDefault("X-Amz-Credential")
  valid_602180 = validateParameter(valid_602180, JString, required = false,
                                 default = nil)
  if valid_602180 != nil:
    section.add "X-Amz-Credential", valid_602180
  var valid_602181 = header.getOrDefault("X-Amz-Security-Token")
  valid_602181 = validateParameter(valid_602181, JString, required = false,
                                 default = nil)
  if valid_602181 != nil:
    section.add "X-Amz-Security-Token", valid_602181
  var valid_602182 = header.getOrDefault("X-Amz-Algorithm")
  valid_602182 = validateParameter(valid_602182, JString, required = false,
                                 default = nil)
  if valid_602182 != nil:
    section.add "X-Amz-Algorithm", valid_602182
  var valid_602183 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602183 = validateParameter(valid_602183, JString, required = false,
                                 default = nil)
  if valid_602183 != nil:
    section.add "X-Amz-SignedHeaders", valid_602183
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602184: Call_ListGroups_602170; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all user groups in Amazon QuickSight. 
  ## 
  let valid = call_602184.validator(path, query, header, formData, body)
  let scheme = call_602184.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602184.url(scheme.get, call_602184.host, call_602184.base,
                         call_602184.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602184, url, valid)

proc call*(call_602185: Call_ListGroups_602170; AwsAccountId: string;
          Namespace: string; maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listGroups
  ## Lists all user groups in Amazon QuickSight. 
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   maxResults: int
  ##             : The maximum number of results to return.
  ##   nextToken: string
  ##            : A pagination token that can be used in a subsequent request.
  var path_602186 = newJObject()
  var query_602187 = newJObject()
  add(path_602186, "AwsAccountId", newJString(AwsAccountId))
  add(path_602186, "Namespace", newJString(Namespace))
  add(query_602187, "max-results", newJInt(maxResults))
  add(query_602187, "next-token", newJString(nextToken))
  result = call_602185.call(path_602186, query_602187, nil, nil, nil)

var listGroups* = Call_ListGroups_602170(name: "listGroups",
                                      meth: HttpMethod.HttpGet,
                                      host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups",
                                      validator: validate_ListGroups_602171,
                                      base: "/", url: url_ListGroups_602172,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGroupMembership_602205 = ref object of OpenApiRestCall_601389
proc url_CreateGroupMembership_602207(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateGroupMembership_602206(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds an Amazon QuickSight user to an Amazon QuickSight group. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupName: JString (required)
  ##            : The name of the group that you want to add the user to.
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   MemberName: JString (required)
  ##             : The name of the user that you want to add to the group membership.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupName` field"
  var valid_602208 = path.getOrDefault("GroupName")
  valid_602208 = validateParameter(valid_602208, JString, required = true,
                                 default = nil)
  if valid_602208 != nil:
    section.add "GroupName", valid_602208
  var valid_602209 = path.getOrDefault("AwsAccountId")
  valid_602209 = validateParameter(valid_602209, JString, required = true,
                                 default = nil)
  if valid_602209 != nil:
    section.add "AwsAccountId", valid_602209
  var valid_602210 = path.getOrDefault("Namespace")
  valid_602210 = validateParameter(valid_602210, JString, required = true,
                                 default = nil)
  if valid_602210 != nil:
    section.add "Namespace", valid_602210
  var valid_602211 = path.getOrDefault("MemberName")
  valid_602211 = validateParameter(valid_602211, JString, required = true,
                                 default = nil)
  if valid_602211 != nil:
    section.add "MemberName", valid_602211
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602212 = header.getOrDefault("X-Amz-Signature")
  valid_602212 = validateParameter(valid_602212, JString, required = false,
                                 default = nil)
  if valid_602212 != nil:
    section.add "X-Amz-Signature", valid_602212
  var valid_602213 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602213 = validateParameter(valid_602213, JString, required = false,
                                 default = nil)
  if valid_602213 != nil:
    section.add "X-Amz-Content-Sha256", valid_602213
  var valid_602214 = header.getOrDefault("X-Amz-Date")
  valid_602214 = validateParameter(valid_602214, JString, required = false,
                                 default = nil)
  if valid_602214 != nil:
    section.add "X-Amz-Date", valid_602214
  var valid_602215 = header.getOrDefault("X-Amz-Credential")
  valid_602215 = validateParameter(valid_602215, JString, required = false,
                                 default = nil)
  if valid_602215 != nil:
    section.add "X-Amz-Credential", valid_602215
  var valid_602216 = header.getOrDefault("X-Amz-Security-Token")
  valid_602216 = validateParameter(valid_602216, JString, required = false,
                                 default = nil)
  if valid_602216 != nil:
    section.add "X-Amz-Security-Token", valid_602216
  var valid_602217 = header.getOrDefault("X-Amz-Algorithm")
  valid_602217 = validateParameter(valid_602217, JString, required = false,
                                 default = nil)
  if valid_602217 != nil:
    section.add "X-Amz-Algorithm", valid_602217
  var valid_602218 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602218 = validateParameter(valid_602218, JString, required = false,
                                 default = nil)
  if valid_602218 != nil:
    section.add "X-Amz-SignedHeaders", valid_602218
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602219: Call_CreateGroupMembership_602205; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds an Amazon QuickSight user to an Amazon QuickSight group. 
  ## 
  let valid = call_602219.validator(path, query, header, formData, body)
  let scheme = call_602219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602219.url(scheme.get, call_602219.host, call_602219.base,
                         call_602219.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602219, url, valid)

proc call*(call_602220: Call_CreateGroupMembership_602205; GroupName: string;
          AwsAccountId: string; Namespace: string; MemberName: string): Recallable =
  ## createGroupMembership
  ## Adds an Amazon QuickSight user to an Amazon QuickSight group. 
  ##   GroupName: string (required)
  ##            : The name of the group that you want to add the user to.
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   MemberName: string (required)
  ##             : The name of the user that you want to add to the group membership.
  var path_602221 = newJObject()
  add(path_602221, "GroupName", newJString(GroupName))
  add(path_602221, "AwsAccountId", newJString(AwsAccountId))
  add(path_602221, "Namespace", newJString(Namespace))
  add(path_602221, "MemberName", newJString(MemberName))
  result = call_602220.call(path_602221, nil, nil, nil, nil)

var createGroupMembership* = Call_CreateGroupMembership_602205(
    name: "createGroupMembership", meth: HttpMethod.HttpPut,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}/members/{MemberName}",
    validator: validate_CreateGroupMembership_602206, base: "/",
    url: url_CreateGroupMembership_602207, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGroupMembership_602222 = ref object of OpenApiRestCall_601389
proc url_DeleteGroupMembership_602224(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteGroupMembership_602223(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes a user from a group so that the user is no longer a member of the group.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupName: JString (required)
  ##            : The name of the group that you want to delete the user from.
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   MemberName: JString (required)
  ##             : The name of the user that you want to delete from the group membership.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupName` field"
  var valid_602225 = path.getOrDefault("GroupName")
  valid_602225 = validateParameter(valid_602225, JString, required = true,
                                 default = nil)
  if valid_602225 != nil:
    section.add "GroupName", valid_602225
  var valid_602226 = path.getOrDefault("AwsAccountId")
  valid_602226 = validateParameter(valid_602226, JString, required = true,
                                 default = nil)
  if valid_602226 != nil:
    section.add "AwsAccountId", valid_602226
  var valid_602227 = path.getOrDefault("Namespace")
  valid_602227 = validateParameter(valid_602227, JString, required = true,
                                 default = nil)
  if valid_602227 != nil:
    section.add "Namespace", valid_602227
  var valid_602228 = path.getOrDefault("MemberName")
  valid_602228 = validateParameter(valid_602228, JString, required = true,
                                 default = nil)
  if valid_602228 != nil:
    section.add "MemberName", valid_602228
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602229 = header.getOrDefault("X-Amz-Signature")
  valid_602229 = validateParameter(valid_602229, JString, required = false,
                                 default = nil)
  if valid_602229 != nil:
    section.add "X-Amz-Signature", valid_602229
  var valid_602230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602230 = validateParameter(valid_602230, JString, required = false,
                                 default = nil)
  if valid_602230 != nil:
    section.add "X-Amz-Content-Sha256", valid_602230
  var valid_602231 = header.getOrDefault("X-Amz-Date")
  valid_602231 = validateParameter(valid_602231, JString, required = false,
                                 default = nil)
  if valid_602231 != nil:
    section.add "X-Amz-Date", valid_602231
  var valid_602232 = header.getOrDefault("X-Amz-Credential")
  valid_602232 = validateParameter(valid_602232, JString, required = false,
                                 default = nil)
  if valid_602232 != nil:
    section.add "X-Amz-Credential", valid_602232
  var valid_602233 = header.getOrDefault("X-Amz-Security-Token")
  valid_602233 = validateParameter(valid_602233, JString, required = false,
                                 default = nil)
  if valid_602233 != nil:
    section.add "X-Amz-Security-Token", valid_602233
  var valid_602234 = header.getOrDefault("X-Amz-Algorithm")
  valid_602234 = validateParameter(valid_602234, JString, required = false,
                                 default = nil)
  if valid_602234 != nil:
    section.add "X-Amz-Algorithm", valid_602234
  var valid_602235 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602235 = validateParameter(valid_602235, JString, required = false,
                                 default = nil)
  if valid_602235 != nil:
    section.add "X-Amz-SignedHeaders", valid_602235
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602236: Call_DeleteGroupMembership_602222; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a user from a group so that the user is no longer a member of the group.
  ## 
  let valid = call_602236.validator(path, query, header, formData, body)
  let scheme = call_602236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602236.url(scheme.get, call_602236.host, call_602236.base,
                         call_602236.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602236, url, valid)

proc call*(call_602237: Call_DeleteGroupMembership_602222; GroupName: string;
          AwsAccountId: string; Namespace: string; MemberName: string): Recallable =
  ## deleteGroupMembership
  ## Removes a user from a group so that the user is no longer a member of the group.
  ##   GroupName: string (required)
  ##            : The name of the group that you want to delete the user from.
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   MemberName: string (required)
  ##             : The name of the user that you want to delete from the group membership.
  var path_602238 = newJObject()
  add(path_602238, "GroupName", newJString(GroupName))
  add(path_602238, "AwsAccountId", newJString(AwsAccountId))
  add(path_602238, "Namespace", newJString(Namespace))
  add(path_602238, "MemberName", newJString(MemberName))
  result = call_602237.call(path_602238, nil, nil, nil, nil)

var deleteGroupMembership* = Call_DeleteGroupMembership_602222(
    name: "deleteGroupMembership", meth: HttpMethod.HttpDelete,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}/members/{MemberName}",
    validator: validate_DeleteGroupMembership_602223, base: "/",
    url: url_DeleteGroupMembership_602224, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIAMPolicyAssignment_602239 = ref object of OpenApiRestCall_601389
proc url_CreateIAMPolicyAssignment_602241(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateIAMPolicyAssignment_602240(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_602242 = path.getOrDefault("AwsAccountId")
  valid_602242 = validateParameter(valid_602242, JString, required = true,
                                 default = nil)
  if valid_602242 != nil:
    section.add "AwsAccountId", valid_602242
  var valid_602243 = path.getOrDefault("Namespace")
  valid_602243 = validateParameter(valid_602243, JString, required = true,
                                 default = nil)
  if valid_602243 != nil:
    section.add "Namespace", valid_602243
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602244 = header.getOrDefault("X-Amz-Signature")
  valid_602244 = validateParameter(valid_602244, JString, required = false,
                                 default = nil)
  if valid_602244 != nil:
    section.add "X-Amz-Signature", valid_602244
  var valid_602245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602245 = validateParameter(valid_602245, JString, required = false,
                                 default = nil)
  if valid_602245 != nil:
    section.add "X-Amz-Content-Sha256", valid_602245
  var valid_602246 = header.getOrDefault("X-Amz-Date")
  valid_602246 = validateParameter(valid_602246, JString, required = false,
                                 default = nil)
  if valid_602246 != nil:
    section.add "X-Amz-Date", valid_602246
  var valid_602247 = header.getOrDefault("X-Amz-Credential")
  valid_602247 = validateParameter(valid_602247, JString, required = false,
                                 default = nil)
  if valid_602247 != nil:
    section.add "X-Amz-Credential", valid_602247
  var valid_602248 = header.getOrDefault("X-Amz-Security-Token")
  valid_602248 = validateParameter(valid_602248, JString, required = false,
                                 default = nil)
  if valid_602248 != nil:
    section.add "X-Amz-Security-Token", valid_602248
  var valid_602249 = header.getOrDefault("X-Amz-Algorithm")
  valid_602249 = validateParameter(valid_602249, JString, required = false,
                                 default = nil)
  if valid_602249 != nil:
    section.add "X-Amz-Algorithm", valid_602249
  var valid_602250 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602250 = validateParameter(valid_602250, JString, required = false,
                                 default = nil)
  if valid_602250 != nil:
    section.add "X-Amz-SignedHeaders", valid_602250
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602252: Call_CreateIAMPolicyAssignment_602239; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an assignment with one specified IAM policy, identified by its Amazon Resource Name (ARN). This policy will be assigned to specified groups or users of Amazon QuickSight. The users and groups need to be in the same namespace. 
  ## 
  let valid = call_602252.validator(path, query, header, formData, body)
  let scheme = call_602252.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602252.url(scheme.get, call_602252.host, call_602252.base,
                         call_602252.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602252, url, valid)

proc call*(call_602253: Call_CreateIAMPolicyAssignment_602239;
          AwsAccountId: string; Namespace: string; body: JsonNode): Recallable =
  ## createIAMPolicyAssignment
  ## Creates an assignment with one specified IAM policy, identified by its Amazon Resource Name (ARN). This policy will be assigned to specified groups or users of Amazon QuickSight. The users and groups need to be in the same namespace. 
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account where you want to assign an IAM policy to QuickSight users or groups.
  ##   Namespace: string (required)
  ##            : The namespace that contains the assignment.
  ##   body: JObject (required)
  var path_602254 = newJObject()
  var body_602255 = newJObject()
  add(path_602254, "AwsAccountId", newJString(AwsAccountId))
  add(path_602254, "Namespace", newJString(Namespace))
  if body != nil:
    body_602255 = body
  result = call_602253.call(path_602254, nil, nil, nil, body_602255)

var createIAMPolicyAssignment* = Call_CreateIAMPolicyAssignment_602239(
    name: "createIAMPolicyAssignment", meth: HttpMethod.HttpPost,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/iam-policy-assignments/",
    validator: validate_CreateIAMPolicyAssignment_602240, base: "/",
    url: url_CreateIAMPolicyAssignment_602241,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTemplate_602274 = ref object of OpenApiRestCall_601389
proc url_UpdateTemplate_602276(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateTemplate_602275(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
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
  var valid_602277 = path.getOrDefault("AwsAccountId")
  valid_602277 = validateParameter(valid_602277, JString, required = true,
                                 default = nil)
  if valid_602277 != nil:
    section.add "AwsAccountId", valid_602277
  var valid_602278 = path.getOrDefault("TemplateId")
  valid_602278 = validateParameter(valid_602278, JString, required = true,
                                 default = nil)
  if valid_602278 != nil:
    section.add "TemplateId", valid_602278
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602279 = header.getOrDefault("X-Amz-Signature")
  valid_602279 = validateParameter(valid_602279, JString, required = false,
                                 default = nil)
  if valid_602279 != nil:
    section.add "X-Amz-Signature", valid_602279
  var valid_602280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602280 = validateParameter(valid_602280, JString, required = false,
                                 default = nil)
  if valid_602280 != nil:
    section.add "X-Amz-Content-Sha256", valid_602280
  var valid_602281 = header.getOrDefault("X-Amz-Date")
  valid_602281 = validateParameter(valid_602281, JString, required = false,
                                 default = nil)
  if valid_602281 != nil:
    section.add "X-Amz-Date", valid_602281
  var valid_602282 = header.getOrDefault("X-Amz-Credential")
  valid_602282 = validateParameter(valid_602282, JString, required = false,
                                 default = nil)
  if valid_602282 != nil:
    section.add "X-Amz-Credential", valid_602282
  var valid_602283 = header.getOrDefault("X-Amz-Security-Token")
  valid_602283 = validateParameter(valid_602283, JString, required = false,
                                 default = nil)
  if valid_602283 != nil:
    section.add "X-Amz-Security-Token", valid_602283
  var valid_602284 = header.getOrDefault("X-Amz-Algorithm")
  valid_602284 = validateParameter(valid_602284, JString, required = false,
                                 default = nil)
  if valid_602284 != nil:
    section.add "X-Amz-Algorithm", valid_602284
  var valid_602285 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602285 = validateParameter(valid_602285, JString, required = false,
                                 default = nil)
  if valid_602285 != nil:
    section.add "X-Amz-SignedHeaders", valid_602285
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602287: Call_UpdateTemplate_602274; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a template from an existing Amazon QuickSight analysis or another template.
  ## 
  let valid = call_602287.validator(path, query, header, formData, body)
  let scheme = call_602287.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602287.url(scheme.get, call_602287.host, call_602287.base,
                         call_602287.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602287, url, valid)

proc call*(call_602288: Call_UpdateTemplate_602274; AwsAccountId: string;
          TemplateId: string; body: JsonNode): Recallable =
  ## updateTemplate
  ## Updates a template from an existing Amazon QuickSight analysis or another template.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the template that you're updating.
  ##   TemplateId: string (required)
  ##             : The ID for the template.
  ##   body: JObject (required)
  var path_602289 = newJObject()
  var body_602290 = newJObject()
  add(path_602289, "AwsAccountId", newJString(AwsAccountId))
  add(path_602289, "TemplateId", newJString(TemplateId))
  if body != nil:
    body_602290 = body
  result = call_602288.call(path_602289, nil, nil, nil, body_602290)

var updateTemplate* = Call_UpdateTemplate_602274(name: "updateTemplate",
    meth: HttpMethod.HttpPut, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates/{TemplateId}",
    validator: validate_UpdateTemplate_602275, base: "/", url: url_UpdateTemplate_602276,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTemplate_602291 = ref object of OpenApiRestCall_601389
proc url_CreateTemplate_602293(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateTemplate_602292(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
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
  var valid_602294 = path.getOrDefault("AwsAccountId")
  valid_602294 = validateParameter(valid_602294, JString, required = true,
                                 default = nil)
  if valid_602294 != nil:
    section.add "AwsAccountId", valid_602294
  var valid_602295 = path.getOrDefault("TemplateId")
  valid_602295 = validateParameter(valid_602295, JString, required = true,
                                 default = nil)
  if valid_602295 != nil:
    section.add "TemplateId", valid_602295
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602296 = header.getOrDefault("X-Amz-Signature")
  valid_602296 = validateParameter(valid_602296, JString, required = false,
                                 default = nil)
  if valid_602296 != nil:
    section.add "X-Amz-Signature", valid_602296
  var valid_602297 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602297 = validateParameter(valid_602297, JString, required = false,
                                 default = nil)
  if valid_602297 != nil:
    section.add "X-Amz-Content-Sha256", valid_602297
  var valid_602298 = header.getOrDefault("X-Amz-Date")
  valid_602298 = validateParameter(valid_602298, JString, required = false,
                                 default = nil)
  if valid_602298 != nil:
    section.add "X-Amz-Date", valid_602298
  var valid_602299 = header.getOrDefault("X-Amz-Credential")
  valid_602299 = validateParameter(valid_602299, JString, required = false,
                                 default = nil)
  if valid_602299 != nil:
    section.add "X-Amz-Credential", valid_602299
  var valid_602300 = header.getOrDefault("X-Amz-Security-Token")
  valid_602300 = validateParameter(valid_602300, JString, required = false,
                                 default = nil)
  if valid_602300 != nil:
    section.add "X-Amz-Security-Token", valid_602300
  var valid_602301 = header.getOrDefault("X-Amz-Algorithm")
  valid_602301 = validateParameter(valid_602301, JString, required = false,
                                 default = nil)
  if valid_602301 != nil:
    section.add "X-Amz-Algorithm", valid_602301
  var valid_602302 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602302 = validateParameter(valid_602302, JString, required = false,
                                 default = nil)
  if valid_602302 != nil:
    section.add "X-Amz-SignedHeaders", valid_602302
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602304: Call_CreateTemplate_602291; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a template from an existing QuickSight analysis or template. You can use the resulting template to create a dashboard.</p> <p>A <i>template</i> is an entity in QuickSight that encapsulates the metadata required to create an analysis and that you can use to create s dashboard. A template adds a layer of abstraction by using placeholders to replace the dataset associated with the analysis. You can use templates to create dashboards by replacing dataset placeholders with datasets that follow the same schema that was used to create the source analysis and template.</p>
  ## 
  let valid = call_602304.validator(path, query, header, formData, body)
  let scheme = call_602304.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602304.url(scheme.get, call_602304.host, call_602304.base,
                         call_602304.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602304, url, valid)

proc call*(call_602305: Call_CreateTemplate_602291; AwsAccountId: string;
          TemplateId: string; body: JsonNode): Recallable =
  ## createTemplate
  ## <p>Creates a template from an existing QuickSight analysis or template. You can use the resulting template to create a dashboard.</p> <p>A <i>template</i> is an entity in QuickSight that encapsulates the metadata required to create an analysis and that you can use to create s dashboard. A template adds a layer of abstraction by using placeholders to replace the dataset associated with the analysis. You can use templates to create dashboards by replacing dataset placeholders with datasets that follow the same schema that was used to create the source analysis and template.</p>
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   TemplateId: string (required)
  ##             : An ID for the template that you want to create. This template is unique per AWS Region in each AWS account.
  ##   body: JObject (required)
  var path_602306 = newJObject()
  var body_602307 = newJObject()
  add(path_602306, "AwsAccountId", newJString(AwsAccountId))
  add(path_602306, "TemplateId", newJString(TemplateId))
  if body != nil:
    body_602307 = body
  result = call_602305.call(path_602306, nil, nil, nil, body_602307)

var createTemplate* = Call_CreateTemplate_602291(name: "createTemplate",
    meth: HttpMethod.HttpPost, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates/{TemplateId}",
    validator: validate_CreateTemplate_602292, base: "/", url: url_CreateTemplate_602293,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTemplate_602256 = ref object of OpenApiRestCall_601389
proc url_DescribeTemplate_602258(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeTemplate_602257(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
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
  var valid_602259 = path.getOrDefault("AwsAccountId")
  valid_602259 = validateParameter(valid_602259, JString, required = true,
                                 default = nil)
  if valid_602259 != nil:
    section.add "AwsAccountId", valid_602259
  var valid_602260 = path.getOrDefault("TemplateId")
  valid_602260 = validateParameter(valid_602260, JString, required = true,
                                 default = nil)
  if valid_602260 != nil:
    section.add "TemplateId", valid_602260
  result.add "path", section
  ## parameters in `query` object:
  ##   version-number: JInt
  ##                 : (Optional) The number for the version to describe. If a <code>VersionNumber</code> parameter value isn't provided, the latest version of the template is described.
  ##   alias-name: JString
  ##             : The alias of the template that you want to describe. If you name a specific alias, you describe the version that the alias points to. You can specify the latest version of the template by providing the keyword <code>$LATEST</code> in the <code>AliasName</code> parameter. The keyword <code>$PUBLISHED</code> doesn't apply to templates.
  section = newJObject()
  var valid_602261 = query.getOrDefault("version-number")
  valid_602261 = validateParameter(valid_602261, JInt, required = false, default = nil)
  if valid_602261 != nil:
    section.add "version-number", valid_602261
  var valid_602262 = query.getOrDefault("alias-name")
  valid_602262 = validateParameter(valid_602262, JString, required = false,
                                 default = nil)
  if valid_602262 != nil:
    section.add "alias-name", valid_602262
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602263 = header.getOrDefault("X-Amz-Signature")
  valid_602263 = validateParameter(valid_602263, JString, required = false,
                                 default = nil)
  if valid_602263 != nil:
    section.add "X-Amz-Signature", valid_602263
  var valid_602264 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602264 = validateParameter(valid_602264, JString, required = false,
                                 default = nil)
  if valid_602264 != nil:
    section.add "X-Amz-Content-Sha256", valid_602264
  var valid_602265 = header.getOrDefault("X-Amz-Date")
  valid_602265 = validateParameter(valid_602265, JString, required = false,
                                 default = nil)
  if valid_602265 != nil:
    section.add "X-Amz-Date", valid_602265
  var valid_602266 = header.getOrDefault("X-Amz-Credential")
  valid_602266 = validateParameter(valid_602266, JString, required = false,
                                 default = nil)
  if valid_602266 != nil:
    section.add "X-Amz-Credential", valid_602266
  var valid_602267 = header.getOrDefault("X-Amz-Security-Token")
  valid_602267 = validateParameter(valid_602267, JString, required = false,
                                 default = nil)
  if valid_602267 != nil:
    section.add "X-Amz-Security-Token", valid_602267
  var valid_602268 = header.getOrDefault("X-Amz-Algorithm")
  valid_602268 = validateParameter(valid_602268, JString, required = false,
                                 default = nil)
  if valid_602268 != nil:
    section.add "X-Amz-Algorithm", valid_602268
  var valid_602269 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602269 = validateParameter(valid_602269, JString, required = false,
                                 default = nil)
  if valid_602269 != nil:
    section.add "X-Amz-SignedHeaders", valid_602269
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602270: Call_DescribeTemplate_602256; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a template's metadata.
  ## 
  let valid = call_602270.validator(path, query, header, formData, body)
  let scheme = call_602270.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602270.url(scheme.get, call_602270.host, call_602270.base,
                         call_602270.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602270, url, valid)

proc call*(call_602271: Call_DescribeTemplate_602256; AwsAccountId: string;
          TemplateId: string; versionNumber: int = 0; aliasName: string = ""): Recallable =
  ## describeTemplate
  ## Describes a template's metadata.
  ##   versionNumber: int
  ##                : (Optional) The number for the version to describe. If a <code>VersionNumber</code> parameter value isn't provided, the latest version of the template is described.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the template that you're describing.
  ##   aliasName: string
  ##            : The alias of the template that you want to describe. If you name a specific alias, you describe the version that the alias points to. You can specify the latest version of the template by providing the keyword <code>$LATEST</code> in the <code>AliasName</code> parameter. The keyword <code>$PUBLISHED</code> doesn't apply to templates.
  ##   TemplateId: string (required)
  ##             : The ID for the template.
  var path_602272 = newJObject()
  var query_602273 = newJObject()
  add(query_602273, "version-number", newJInt(versionNumber))
  add(path_602272, "AwsAccountId", newJString(AwsAccountId))
  add(query_602273, "alias-name", newJString(aliasName))
  add(path_602272, "TemplateId", newJString(TemplateId))
  result = call_602271.call(path_602272, query_602273, nil, nil, nil)

var describeTemplate* = Call_DescribeTemplate_602256(name: "describeTemplate",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates/{TemplateId}",
    validator: validate_DescribeTemplate_602257, base: "/",
    url: url_DescribeTemplate_602258, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTemplate_602308 = ref object of OpenApiRestCall_601389
proc url_DeleteTemplate_602310(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteTemplate_602309(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
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
  var valid_602311 = path.getOrDefault("AwsAccountId")
  valid_602311 = validateParameter(valid_602311, JString, required = true,
                                 default = nil)
  if valid_602311 != nil:
    section.add "AwsAccountId", valid_602311
  var valid_602312 = path.getOrDefault("TemplateId")
  valid_602312 = validateParameter(valid_602312, JString, required = true,
                                 default = nil)
  if valid_602312 != nil:
    section.add "TemplateId", valid_602312
  result.add "path", section
  ## parameters in `query` object:
  ##   version-number: JInt
  ##                 : Specifies the version of the template that you want to delete. If you don't provide a version number, <code>DeleteTemplate</code> deletes all versions of the template. 
  section = newJObject()
  var valid_602313 = query.getOrDefault("version-number")
  valid_602313 = validateParameter(valid_602313, JInt, required = false, default = nil)
  if valid_602313 != nil:
    section.add "version-number", valid_602313
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602314 = header.getOrDefault("X-Amz-Signature")
  valid_602314 = validateParameter(valid_602314, JString, required = false,
                                 default = nil)
  if valid_602314 != nil:
    section.add "X-Amz-Signature", valid_602314
  var valid_602315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602315 = validateParameter(valid_602315, JString, required = false,
                                 default = nil)
  if valid_602315 != nil:
    section.add "X-Amz-Content-Sha256", valid_602315
  var valid_602316 = header.getOrDefault("X-Amz-Date")
  valid_602316 = validateParameter(valid_602316, JString, required = false,
                                 default = nil)
  if valid_602316 != nil:
    section.add "X-Amz-Date", valid_602316
  var valid_602317 = header.getOrDefault("X-Amz-Credential")
  valid_602317 = validateParameter(valid_602317, JString, required = false,
                                 default = nil)
  if valid_602317 != nil:
    section.add "X-Amz-Credential", valid_602317
  var valid_602318 = header.getOrDefault("X-Amz-Security-Token")
  valid_602318 = validateParameter(valid_602318, JString, required = false,
                                 default = nil)
  if valid_602318 != nil:
    section.add "X-Amz-Security-Token", valid_602318
  var valid_602319 = header.getOrDefault("X-Amz-Algorithm")
  valid_602319 = validateParameter(valid_602319, JString, required = false,
                                 default = nil)
  if valid_602319 != nil:
    section.add "X-Amz-Algorithm", valid_602319
  var valid_602320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602320 = validateParameter(valid_602320, JString, required = false,
                                 default = nil)
  if valid_602320 != nil:
    section.add "X-Amz-SignedHeaders", valid_602320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602321: Call_DeleteTemplate_602308; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a template.
  ## 
  let valid = call_602321.validator(path, query, header, formData, body)
  let scheme = call_602321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602321.url(scheme.get, call_602321.host, call_602321.base,
                         call_602321.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602321, url, valid)

proc call*(call_602322: Call_DeleteTemplate_602308; AwsAccountId: string;
          TemplateId: string; versionNumber: int = 0): Recallable =
  ## deleteTemplate
  ## Deletes a template.
  ##   versionNumber: int
  ##                : Specifies the version of the template that you want to delete. If you don't provide a version number, <code>DeleteTemplate</code> deletes all versions of the template. 
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the template that you're deleting.
  ##   TemplateId: string (required)
  ##             : An ID for the template you want to delete.
  var path_602323 = newJObject()
  var query_602324 = newJObject()
  add(query_602324, "version-number", newJInt(versionNumber))
  add(path_602323, "AwsAccountId", newJString(AwsAccountId))
  add(path_602323, "TemplateId", newJString(TemplateId))
  result = call_602322.call(path_602323, query_602324, nil, nil, nil)

var deleteTemplate* = Call_DeleteTemplate_602308(name: "deleteTemplate",
    meth: HttpMethod.HttpDelete, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates/{TemplateId}",
    validator: validate_DeleteTemplate_602309, base: "/", url: url_DeleteTemplate_602310,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTemplateAlias_602341 = ref object of OpenApiRestCall_601389
proc url_UpdateTemplateAlias_602343(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateTemplateAlias_602342(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Updates the template alias of a template.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account that contains the template alias that you're updating.
  ##   AliasName: JString (required)
  ##            : The alias of the template that you want to update. If you name a specific alias, you update the version that the alias points to. You can specify the latest version of the template by providing the keyword <code>$LATEST</code> in the <code>AliasName</code> parameter. The keyword <code>$PUBLISHED</code> doesn't apply to templates.
  ##   TemplateId: JString (required)
  ##             : The ID for the template.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_602344 = path.getOrDefault("AwsAccountId")
  valid_602344 = validateParameter(valid_602344, JString, required = true,
                                 default = nil)
  if valid_602344 != nil:
    section.add "AwsAccountId", valid_602344
  var valid_602345 = path.getOrDefault("AliasName")
  valid_602345 = validateParameter(valid_602345, JString, required = true,
                                 default = nil)
  if valid_602345 != nil:
    section.add "AliasName", valid_602345
  var valid_602346 = path.getOrDefault("TemplateId")
  valid_602346 = validateParameter(valid_602346, JString, required = true,
                                 default = nil)
  if valid_602346 != nil:
    section.add "TemplateId", valid_602346
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602347 = header.getOrDefault("X-Amz-Signature")
  valid_602347 = validateParameter(valid_602347, JString, required = false,
                                 default = nil)
  if valid_602347 != nil:
    section.add "X-Amz-Signature", valid_602347
  var valid_602348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602348 = validateParameter(valid_602348, JString, required = false,
                                 default = nil)
  if valid_602348 != nil:
    section.add "X-Amz-Content-Sha256", valid_602348
  var valid_602349 = header.getOrDefault("X-Amz-Date")
  valid_602349 = validateParameter(valid_602349, JString, required = false,
                                 default = nil)
  if valid_602349 != nil:
    section.add "X-Amz-Date", valid_602349
  var valid_602350 = header.getOrDefault("X-Amz-Credential")
  valid_602350 = validateParameter(valid_602350, JString, required = false,
                                 default = nil)
  if valid_602350 != nil:
    section.add "X-Amz-Credential", valid_602350
  var valid_602351 = header.getOrDefault("X-Amz-Security-Token")
  valid_602351 = validateParameter(valid_602351, JString, required = false,
                                 default = nil)
  if valid_602351 != nil:
    section.add "X-Amz-Security-Token", valid_602351
  var valid_602352 = header.getOrDefault("X-Amz-Algorithm")
  valid_602352 = validateParameter(valid_602352, JString, required = false,
                                 default = nil)
  if valid_602352 != nil:
    section.add "X-Amz-Algorithm", valid_602352
  var valid_602353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602353 = validateParameter(valid_602353, JString, required = false,
                                 default = nil)
  if valid_602353 != nil:
    section.add "X-Amz-SignedHeaders", valid_602353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602355: Call_UpdateTemplateAlias_602341; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the template alias of a template.
  ## 
  let valid = call_602355.validator(path, query, header, formData, body)
  let scheme = call_602355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602355.url(scheme.get, call_602355.host, call_602355.base,
                         call_602355.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602355, url, valid)

proc call*(call_602356: Call_UpdateTemplateAlias_602341; AwsAccountId: string;
          AliasName: string; TemplateId: string; body: JsonNode): Recallable =
  ## updateTemplateAlias
  ## Updates the template alias of a template.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the template alias that you're updating.
  ##   AliasName: string (required)
  ##            : The alias of the template that you want to update. If you name a specific alias, you update the version that the alias points to. You can specify the latest version of the template by providing the keyword <code>$LATEST</code> in the <code>AliasName</code> parameter. The keyword <code>$PUBLISHED</code> doesn't apply to templates.
  ##   TemplateId: string (required)
  ##             : The ID for the template.
  ##   body: JObject (required)
  var path_602357 = newJObject()
  var body_602358 = newJObject()
  add(path_602357, "AwsAccountId", newJString(AwsAccountId))
  add(path_602357, "AliasName", newJString(AliasName))
  add(path_602357, "TemplateId", newJString(TemplateId))
  if body != nil:
    body_602358 = body
  result = call_602356.call(path_602357, nil, nil, nil, body_602358)

var updateTemplateAlias* = Call_UpdateTemplateAlias_602341(
    name: "updateTemplateAlias", meth: HttpMethod.HttpPut,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/templates/{TemplateId}/aliases/{AliasName}",
    validator: validate_UpdateTemplateAlias_602342, base: "/",
    url: url_UpdateTemplateAlias_602343, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTemplateAlias_602359 = ref object of OpenApiRestCall_601389
proc url_CreateTemplateAlias_602361(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateTemplateAlias_602360(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Creates a template alias for a template.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account that contains the template that you creating an alias for.
  ##   AliasName: JString (required)
  ##            : The name that you want to give to the template alias that you're creating. Don't start the alias name with the <code>$</code> character. Alias names that start with <code>$</code> are reserved by QuickSight. 
  ##   TemplateId: JString (required)
  ##             : An ID for the template.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_602362 = path.getOrDefault("AwsAccountId")
  valid_602362 = validateParameter(valid_602362, JString, required = true,
                                 default = nil)
  if valid_602362 != nil:
    section.add "AwsAccountId", valid_602362
  var valid_602363 = path.getOrDefault("AliasName")
  valid_602363 = validateParameter(valid_602363, JString, required = true,
                                 default = nil)
  if valid_602363 != nil:
    section.add "AliasName", valid_602363
  var valid_602364 = path.getOrDefault("TemplateId")
  valid_602364 = validateParameter(valid_602364, JString, required = true,
                                 default = nil)
  if valid_602364 != nil:
    section.add "TemplateId", valid_602364
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602365 = header.getOrDefault("X-Amz-Signature")
  valid_602365 = validateParameter(valid_602365, JString, required = false,
                                 default = nil)
  if valid_602365 != nil:
    section.add "X-Amz-Signature", valid_602365
  var valid_602366 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602366 = validateParameter(valid_602366, JString, required = false,
                                 default = nil)
  if valid_602366 != nil:
    section.add "X-Amz-Content-Sha256", valid_602366
  var valid_602367 = header.getOrDefault("X-Amz-Date")
  valid_602367 = validateParameter(valid_602367, JString, required = false,
                                 default = nil)
  if valid_602367 != nil:
    section.add "X-Amz-Date", valid_602367
  var valid_602368 = header.getOrDefault("X-Amz-Credential")
  valid_602368 = validateParameter(valid_602368, JString, required = false,
                                 default = nil)
  if valid_602368 != nil:
    section.add "X-Amz-Credential", valid_602368
  var valid_602369 = header.getOrDefault("X-Amz-Security-Token")
  valid_602369 = validateParameter(valid_602369, JString, required = false,
                                 default = nil)
  if valid_602369 != nil:
    section.add "X-Amz-Security-Token", valid_602369
  var valid_602370 = header.getOrDefault("X-Amz-Algorithm")
  valid_602370 = validateParameter(valid_602370, JString, required = false,
                                 default = nil)
  if valid_602370 != nil:
    section.add "X-Amz-Algorithm", valid_602370
  var valid_602371 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602371 = validateParameter(valid_602371, JString, required = false,
                                 default = nil)
  if valid_602371 != nil:
    section.add "X-Amz-SignedHeaders", valid_602371
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602373: Call_CreateTemplateAlias_602359; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a template alias for a template.
  ## 
  let valid = call_602373.validator(path, query, header, formData, body)
  let scheme = call_602373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602373.url(scheme.get, call_602373.host, call_602373.base,
                         call_602373.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602373, url, valid)

proc call*(call_602374: Call_CreateTemplateAlias_602359; AwsAccountId: string;
          AliasName: string; TemplateId: string; body: JsonNode): Recallable =
  ## createTemplateAlias
  ## Creates a template alias for a template.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the template that you creating an alias for.
  ##   AliasName: string (required)
  ##            : The name that you want to give to the template alias that you're creating. Don't start the alias name with the <code>$</code> character. Alias names that start with <code>$</code> are reserved by QuickSight. 
  ##   TemplateId: string (required)
  ##             : An ID for the template.
  ##   body: JObject (required)
  var path_602375 = newJObject()
  var body_602376 = newJObject()
  add(path_602375, "AwsAccountId", newJString(AwsAccountId))
  add(path_602375, "AliasName", newJString(AliasName))
  add(path_602375, "TemplateId", newJString(TemplateId))
  if body != nil:
    body_602376 = body
  result = call_602374.call(path_602375, nil, nil, nil, body_602376)

var createTemplateAlias* = Call_CreateTemplateAlias_602359(
    name: "createTemplateAlias", meth: HttpMethod.HttpPost,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/templates/{TemplateId}/aliases/{AliasName}",
    validator: validate_CreateTemplateAlias_602360, base: "/",
    url: url_CreateTemplateAlias_602361, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTemplateAlias_602325 = ref object of OpenApiRestCall_601389
proc url_DescribeTemplateAlias_602327(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeTemplateAlias_602326(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the template alias for a template.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account that contains the template alias that you're describing.
  ##   AliasName: JString (required)
  ##            : The name of the template alias that you want to describe. If you name a specific alias, you describe the version that the alias points to. You can specify the latest version of the template by providing the keyword <code>$LATEST</code> in the <code>AliasName</code> parameter. The keyword <code>$PUBLISHED</code> doesn't apply to templates.
  ##   TemplateId: JString (required)
  ##             : The ID for the template.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_602328 = path.getOrDefault("AwsAccountId")
  valid_602328 = validateParameter(valid_602328, JString, required = true,
                                 default = nil)
  if valid_602328 != nil:
    section.add "AwsAccountId", valid_602328
  var valid_602329 = path.getOrDefault("AliasName")
  valid_602329 = validateParameter(valid_602329, JString, required = true,
                                 default = nil)
  if valid_602329 != nil:
    section.add "AliasName", valid_602329
  var valid_602330 = path.getOrDefault("TemplateId")
  valid_602330 = validateParameter(valid_602330, JString, required = true,
                                 default = nil)
  if valid_602330 != nil:
    section.add "TemplateId", valid_602330
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602331 = header.getOrDefault("X-Amz-Signature")
  valid_602331 = validateParameter(valid_602331, JString, required = false,
                                 default = nil)
  if valid_602331 != nil:
    section.add "X-Amz-Signature", valid_602331
  var valid_602332 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602332 = validateParameter(valid_602332, JString, required = false,
                                 default = nil)
  if valid_602332 != nil:
    section.add "X-Amz-Content-Sha256", valid_602332
  var valid_602333 = header.getOrDefault("X-Amz-Date")
  valid_602333 = validateParameter(valid_602333, JString, required = false,
                                 default = nil)
  if valid_602333 != nil:
    section.add "X-Amz-Date", valid_602333
  var valid_602334 = header.getOrDefault("X-Amz-Credential")
  valid_602334 = validateParameter(valid_602334, JString, required = false,
                                 default = nil)
  if valid_602334 != nil:
    section.add "X-Amz-Credential", valid_602334
  var valid_602335 = header.getOrDefault("X-Amz-Security-Token")
  valid_602335 = validateParameter(valid_602335, JString, required = false,
                                 default = nil)
  if valid_602335 != nil:
    section.add "X-Amz-Security-Token", valid_602335
  var valid_602336 = header.getOrDefault("X-Amz-Algorithm")
  valid_602336 = validateParameter(valid_602336, JString, required = false,
                                 default = nil)
  if valid_602336 != nil:
    section.add "X-Amz-Algorithm", valid_602336
  var valid_602337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602337 = validateParameter(valid_602337, JString, required = false,
                                 default = nil)
  if valid_602337 != nil:
    section.add "X-Amz-SignedHeaders", valid_602337
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602338: Call_DescribeTemplateAlias_602325; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the template alias for a template.
  ## 
  let valid = call_602338.validator(path, query, header, formData, body)
  let scheme = call_602338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602338.url(scheme.get, call_602338.host, call_602338.base,
                         call_602338.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602338, url, valid)

proc call*(call_602339: Call_DescribeTemplateAlias_602325; AwsAccountId: string;
          AliasName: string; TemplateId: string): Recallable =
  ## describeTemplateAlias
  ## Describes the template alias for a template.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the template alias that you're describing.
  ##   AliasName: string (required)
  ##            : The name of the template alias that you want to describe. If you name a specific alias, you describe the version that the alias points to. You can specify the latest version of the template by providing the keyword <code>$LATEST</code> in the <code>AliasName</code> parameter. The keyword <code>$PUBLISHED</code> doesn't apply to templates.
  ##   TemplateId: string (required)
  ##             : The ID for the template.
  var path_602340 = newJObject()
  add(path_602340, "AwsAccountId", newJString(AwsAccountId))
  add(path_602340, "AliasName", newJString(AliasName))
  add(path_602340, "TemplateId", newJString(TemplateId))
  result = call_602339.call(path_602340, nil, nil, nil, nil)

var describeTemplateAlias* = Call_DescribeTemplateAlias_602325(
    name: "describeTemplateAlias", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/templates/{TemplateId}/aliases/{AliasName}",
    validator: validate_DescribeTemplateAlias_602326, base: "/",
    url: url_DescribeTemplateAlias_602327, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTemplateAlias_602377 = ref object of OpenApiRestCall_601389
proc url_DeleteTemplateAlias_602379(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteTemplateAlias_602378(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Deletes the item that the specified template alias points to. If you provide a specific alias, you delete the version of the template that the alias points to.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account that contains the item to delete.
  ##   AliasName: JString (required)
  ##            : The name for the template alias. If you name a specific alias, you delete the version that the alias points to. You can specify the latest version of the template by providing the keyword <code>$LATEST</code> in the <code>AliasName</code> parameter. 
  ##   TemplateId: JString (required)
  ##             : The ID for the template that the specified alias is for.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_602380 = path.getOrDefault("AwsAccountId")
  valid_602380 = validateParameter(valid_602380, JString, required = true,
                                 default = nil)
  if valid_602380 != nil:
    section.add "AwsAccountId", valid_602380
  var valid_602381 = path.getOrDefault("AliasName")
  valid_602381 = validateParameter(valid_602381, JString, required = true,
                                 default = nil)
  if valid_602381 != nil:
    section.add "AliasName", valid_602381
  var valid_602382 = path.getOrDefault("TemplateId")
  valid_602382 = validateParameter(valid_602382, JString, required = true,
                                 default = nil)
  if valid_602382 != nil:
    section.add "TemplateId", valid_602382
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602383 = header.getOrDefault("X-Amz-Signature")
  valid_602383 = validateParameter(valid_602383, JString, required = false,
                                 default = nil)
  if valid_602383 != nil:
    section.add "X-Amz-Signature", valid_602383
  var valid_602384 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602384 = validateParameter(valid_602384, JString, required = false,
                                 default = nil)
  if valid_602384 != nil:
    section.add "X-Amz-Content-Sha256", valid_602384
  var valid_602385 = header.getOrDefault("X-Amz-Date")
  valid_602385 = validateParameter(valid_602385, JString, required = false,
                                 default = nil)
  if valid_602385 != nil:
    section.add "X-Amz-Date", valid_602385
  var valid_602386 = header.getOrDefault("X-Amz-Credential")
  valid_602386 = validateParameter(valid_602386, JString, required = false,
                                 default = nil)
  if valid_602386 != nil:
    section.add "X-Amz-Credential", valid_602386
  var valid_602387 = header.getOrDefault("X-Amz-Security-Token")
  valid_602387 = validateParameter(valid_602387, JString, required = false,
                                 default = nil)
  if valid_602387 != nil:
    section.add "X-Amz-Security-Token", valid_602387
  var valid_602388 = header.getOrDefault("X-Amz-Algorithm")
  valid_602388 = validateParameter(valid_602388, JString, required = false,
                                 default = nil)
  if valid_602388 != nil:
    section.add "X-Amz-Algorithm", valid_602388
  var valid_602389 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602389 = validateParameter(valid_602389, JString, required = false,
                                 default = nil)
  if valid_602389 != nil:
    section.add "X-Amz-SignedHeaders", valid_602389
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602390: Call_DeleteTemplateAlias_602377; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the item that the specified template alias points to. If you provide a specific alias, you delete the version of the template that the alias points to.
  ## 
  let valid = call_602390.validator(path, query, header, formData, body)
  let scheme = call_602390.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602390.url(scheme.get, call_602390.host, call_602390.base,
                         call_602390.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602390, url, valid)

proc call*(call_602391: Call_DeleteTemplateAlias_602377; AwsAccountId: string;
          AliasName: string; TemplateId: string): Recallable =
  ## deleteTemplateAlias
  ## Deletes the item that the specified template alias points to. If you provide a specific alias, you delete the version of the template that the alias points to.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the item to delete.
  ##   AliasName: string (required)
  ##            : The name for the template alias. If you name a specific alias, you delete the version that the alias points to. You can specify the latest version of the template by providing the keyword <code>$LATEST</code> in the <code>AliasName</code> parameter. 
  ##   TemplateId: string (required)
  ##             : The ID for the template that the specified alias is for.
  var path_602392 = newJObject()
  add(path_602392, "AwsAccountId", newJString(AwsAccountId))
  add(path_602392, "AliasName", newJString(AliasName))
  add(path_602392, "TemplateId", newJString(TemplateId))
  result = call_602391.call(path_602392, nil, nil, nil, nil)

var deleteTemplateAlias* = Call_DeleteTemplateAlias_602377(
    name: "deleteTemplateAlias", meth: HttpMethod.HttpDelete,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/templates/{TemplateId}/aliases/{AliasName}",
    validator: validate_DeleteTemplateAlias_602378, base: "/",
    url: url_DeleteTemplateAlias_602379, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDataSet_602408 = ref object of OpenApiRestCall_601389
proc url_UpdateDataSet_602410(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDataSet_602409(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_602411 = path.getOrDefault("AwsAccountId")
  valid_602411 = validateParameter(valid_602411, JString, required = true,
                                 default = nil)
  if valid_602411 != nil:
    section.add "AwsAccountId", valid_602411
  var valid_602412 = path.getOrDefault("DataSetId")
  valid_602412 = validateParameter(valid_602412, JString, required = true,
                                 default = nil)
  if valid_602412 != nil:
    section.add "DataSetId", valid_602412
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602413 = header.getOrDefault("X-Amz-Signature")
  valid_602413 = validateParameter(valid_602413, JString, required = false,
                                 default = nil)
  if valid_602413 != nil:
    section.add "X-Amz-Signature", valid_602413
  var valid_602414 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602414 = validateParameter(valid_602414, JString, required = false,
                                 default = nil)
  if valid_602414 != nil:
    section.add "X-Amz-Content-Sha256", valid_602414
  var valid_602415 = header.getOrDefault("X-Amz-Date")
  valid_602415 = validateParameter(valid_602415, JString, required = false,
                                 default = nil)
  if valid_602415 != nil:
    section.add "X-Amz-Date", valid_602415
  var valid_602416 = header.getOrDefault("X-Amz-Credential")
  valid_602416 = validateParameter(valid_602416, JString, required = false,
                                 default = nil)
  if valid_602416 != nil:
    section.add "X-Amz-Credential", valid_602416
  var valid_602417 = header.getOrDefault("X-Amz-Security-Token")
  valid_602417 = validateParameter(valid_602417, JString, required = false,
                                 default = nil)
  if valid_602417 != nil:
    section.add "X-Amz-Security-Token", valid_602417
  var valid_602418 = header.getOrDefault("X-Amz-Algorithm")
  valid_602418 = validateParameter(valid_602418, JString, required = false,
                                 default = nil)
  if valid_602418 != nil:
    section.add "X-Amz-Algorithm", valid_602418
  var valid_602419 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602419 = validateParameter(valid_602419, JString, required = false,
                                 default = nil)
  if valid_602419 != nil:
    section.add "X-Amz-SignedHeaders", valid_602419
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602421: Call_UpdateDataSet_602408; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a dataset.
  ## 
  let valid = call_602421.validator(path, query, header, formData, body)
  let scheme = call_602421.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602421.url(scheme.get, call_602421.host, call_602421.base,
                         call_602421.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602421, url, valid)

proc call*(call_602422: Call_UpdateDataSet_602408; AwsAccountId: string;
          DataSetId: string; body: JsonNode): Recallable =
  ## updateDataSet
  ## Updates a dataset.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSetId: string (required)
  ##            : The ID for the dataset that you want to update. This ID is unique per AWS Region for each AWS account.
  ##   body: JObject (required)
  var path_602423 = newJObject()
  var body_602424 = newJObject()
  add(path_602423, "AwsAccountId", newJString(AwsAccountId))
  add(path_602423, "DataSetId", newJString(DataSetId))
  if body != nil:
    body_602424 = body
  result = call_602422.call(path_602423, nil, nil, nil, body_602424)

var updateDataSet* = Call_UpdateDataSet_602408(name: "updateDataSet",
    meth: HttpMethod.HttpPut, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}",
    validator: validate_UpdateDataSet_602409, base: "/", url: url_UpdateDataSet_602410,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDataSet_602393 = ref object of OpenApiRestCall_601389
proc url_DescribeDataSet_602395(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeDataSet_602394(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
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
  var valid_602396 = path.getOrDefault("AwsAccountId")
  valid_602396 = validateParameter(valid_602396, JString, required = true,
                                 default = nil)
  if valid_602396 != nil:
    section.add "AwsAccountId", valid_602396
  var valid_602397 = path.getOrDefault("DataSetId")
  valid_602397 = validateParameter(valid_602397, JString, required = true,
                                 default = nil)
  if valid_602397 != nil:
    section.add "DataSetId", valid_602397
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602398 = header.getOrDefault("X-Amz-Signature")
  valid_602398 = validateParameter(valid_602398, JString, required = false,
                                 default = nil)
  if valid_602398 != nil:
    section.add "X-Amz-Signature", valid_602398
  var valid_602399 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602399 = validateParameter(valid_602399, JString, required = false,
                                 default = nil)
  if valid_602399 != nil:
    section.add "X-Amz-Content-Sha256", valid_602399
  var valid_602400 = header.getOrDefault("X-Amz-Date")
  valid_602400 = validateParameter(valid_602400, JString, required = false,
                                 default = nil)
  if valid_602400 != nil:
    section.add "X-Amz-Date", valid_602400
  var valid_602401 = header.getOrDefault("X-Amz-Credential")
  valid_602401 = validateParameter(valid_602401, JString, required = false,
                                 default = nil)
  if valid_602401 != nil:
    section.add "X-Amz-Credential", valid_602401
  var valid_602402 = header.getOrDefault("X-Amz-Security-Token")
  valid_602402 = validateParameter(valid_602402, JString, required = false,
                                 default = nil)
  if valid_602402 != nil:
    section.add "X-Amz-Security-Token", valid_602402
  var valid_602403 = header.getOrDefault("X-Amz-Algorithm")
  valid_602403 = validateParameter(valid_602403, JString, required = false,
                                 default = nil)
  if valid_602403 != nil:
    section.add "X-Amz-Algorithm", valid_602403
  var valid_602404 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602404 = validateParameter(valid_602404, JString, required = false,
                                 default = nil)
  if valid_602404 != nil:
    section.add "X-Amz-SignedHeaders", valid_602404
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602405: Call_DescribeDataSet_602393; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a dataset. 
  ## 
  let valid = call_602405.validator(path, query, header, formData, body)
  let scheme = call_602405.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602405.url(scheme.get, call_602405.host, call_602405.base,
                         call_602405.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602405, url, valid)

proc call*(call_602406: Call_DescribeDataSet_602393; AwsAccountId: string;
          DataSetId: string): Recallable =
  ## describeDataSet
  ## Describes a dataset. 
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSetId: string (required)
  ##            : The ID for the dataset that you want to create. This ID is unique per AWS Region for each AWS account.
  var path_602407 = newJObject()
  add(path_602407, "AwsAccountId", newJString(AwsAccountId))
  add(path_602407, "DataSetId", newJString(DataSetId))
  result = call_602406.call(path_602407, nil, nil, nil, nil)

var describeDataSet* = Call_DescribeDataSet_602393(name: "describeDataSet",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}",
    validator: validate_DescribeDataSet_602394, base: "/", url: url_DescribeDataSet_602395,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDataSet_602425 = ref object of OpenApiRestCall_601389
proc url_DeleteDataSet_602427(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDataSet_602426(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_602428 = path.getOrDefault("AwsAccountId")
  valid_602428 = validateParameter(valid_602428, JString, required = true,
                                 default = nil)
  if valid_602428 != nil:
    section.add "AwsAccountId", valid_602428
  var valid_602429 = path.getOrDefault("DataSetId")
  valid_602429 = validateParameter(valid_602429, JString, required = true,
                                 default = nil)
  if valid_602429 != nil:
    section.add "DataSetId", valid_602429
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602430 = header.getOrDefault("X-Amz-Signature")
  valid_602430 = validateParameter(valid_602430, JString, required = false,
                                 default = nil)
  if valid_602430 != nil:
    section.add "X-Amz-Signature", valid_602430
  var valid_602431 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602431 = validateParameter(valid_602431, JString, required = false,
                                 default = nil)
  if valid_602431 != nil:
    section.add "X-Amz-Content-Sha256", valid_602431
  var valid_602432 = header.getOrDefault("X-Amz-Date")
  valid_602432 = validateParameter(valid_602432, JString, required = false,
                                 default = nil)
  if valid_602432 != nil:
    section.add "X-Amz-Date", valid_602432
  var valid_602433 = header.getOrDefault("X-Amz-Credential")
  valid_602433 = validateParameter(valid_602433, JString, required = false,
                                 default = nil)
  if valid_602433 != nil:
    section.add "X-Amz-Credential", valid_602433
  var valid_602434 = header.getOrDefault("X-Amz-Security-Token")
  valid_602434 = validateParameter(valid_602434, JString, required = false,
                                 default = nil)
  if valid_602434 != nil:
    section.add "X-Amz-Security-Token", valid_602434
  var valid_602435 = header.getOrDefault("X-Amz-Algorithm")
  valid_602435 = validateParameter(valid_602435, JString, required = false,
                                 default = nil)
  if valid_602435 != nil:
    section.add "X-Amz-Algorithm", valid_602435
  var valid_602436 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602436 = validateParameter(valid_602436, JString, required = false,
                                 default = nil)
  if valid_602436 != nil:
    section.add "X-Amz-SignedHeaders", valid_602436
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602437: Call_DeleteDataSet_602425; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a dataset.
  ## 
  let valid = call_602437.validator(path, query, header, formData, body)
  let scheme = call_602437.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602437.url(scheme.get, call_602437.host, call_602437.base,
                         call_602437.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602437, url, valid)

proc call*(call_602438: Call_DeleteDataSet_602425; AwsAccountId: string;
          DataSetId: string): Recallable =
  ## deleteDataSet
  ## Deletes a dataset.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSetId: string (required)
  ##            : The ID for the dataset that you want to create. This ID is unique per AWS Region for each AWS account.
  var path_602439 = newJObject()
  add(path_602439, "AwsAccountId", newJString(AwsAccountId))
  add(path_602439, "DataSetId", newJString(DataSetId))
  result = call_602438.call(path_602439, nil, nil, nil, nil)

var deleteDataSet* = Call_DeleteDataSet_602425(name: "deleteDataSet",
    meth: HttpMethod.HttpDelete, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}",
    validator: validate_DeleteDataSet_602426, base: "/", url: url_DeleteDataSet_602427,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDataSource_602455 = ref object of OpenApiRestCall_601389
proc url_UpdateDataSource_602457(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDataSource_602456(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Updates a data source.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DataSourceId: JString (required)
  ##               : The ID of the data source. This ID is unique per AWS Region for each AWS account. 
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `DataSourceId` field"
  var valid_602458 = path.getOrDefault("DataSourceId")
  valid_602458 = validateParameter(valid_602458, JString, required = true,
                                 default = nil)
  if valid_602458 != nil:
    section.add "DataSourceId", valid_602458
  var valid_602459 = path.getOrDefault("AwsAccountId")
  valid_602459 = validateParameter(valid_602459, JString, required = true,
                                 default = nil)
  if valid_602459 != nil:
    section.add "AwsAccountId", valid_602459
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602460 = header.getOrDefault("X-Amz-Signature")
  valid_602460 = validateParameter(valid_602460, JString, required = false,
                                 default = nil)
  if valid_602460 != nil:
    section.add "X-Amz-Signature", valid_602460
  var valid_602461 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602461 = validateParameter(valid_602461, JString, required = false,
                                 default = nil)
  if valid_602461 != nil:
    section.add "X-Amz-Content-Sha256", valid_602461
  var valid_602462 = header.getOrDefault("X-Amz-Date")
  valid_602462 = validateParameter(valid_602462, JString, required = false,
                                 default = nil)
  if valid_602462 != nil:
    section.add "X-Amz-Date", valid_602462
  var valid_602463 = header.getOrDefault("X-Amz-Credential")
  valid_602463 = validateParameter(valid_602463, JString, required = false,
                                 default = nil)
  if valid_602463 != nil:
    section.add "X-Amz-Credential", valid_602463
  var valid_602464 = header.getOrDefault("X-Amz-Security-Token")
  valid_602464 = validateParameter(valid_602464, JString, required = false,
                                 default = nil)
  if valid_602464 != nil:
    section.add "X-Amz-Security-Token", valid_602464
  var valid_602465 = header.getOrDefault("X-Amz-Algorithm")
  valid_602465 = validateParameter(valid_602465, JString, required = false,
                                 default = nil)
  if valid_602465 != nil:
    section.add "X-Amz-Algorithm", valid_602465
  var valid_602466 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602466 = validateParameter(valid_602466, JString, required = false,
                                 default = nil)
  if valid_602466 != nil:
    section.add "X-Amz-SignedHeaders", valid_602466
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602468: Call_UpdateDataSource_602455; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a data source.
  ## 
  let valid = call_602468.validator(path, query, header, formData, body)
  let scheme = call_602468.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602468.url(scheme.get, call_602468.host, call_602468.base,
                         call_602468.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602468, url, valid)

proc call*(call_602469: Call_UpdateDataSource_602455; DataSourceId: string;
          AwsAccountId: string; body: JsonNode): Recallable =
  ## updateDataSource
  ## Updates a data source.
  ##   DataSourceId: string (required)
  ##               : The ID of the data source. This ID is unique per AWS Region for each AWS account. 
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   body: JObject (required)
  var path_602470 = newJObject()
  var body_602471 = newJObject()
  add(path_602470, "DataSourceId", newJString(DataSourceId))
  add(path_602470, "AwsAccountId", newJString(AwsAccountId))
  if body != nil:
    body_602471 = body
  result = call_602469.call(path_602470, nil, nil, nil, body_602471)

var updateDataSource* = Call_UpdateDataSource_602455(name: "updateDataSource",
    meth: HttpMethod.HttpPut, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sources/{DataSourceId}",
    validator: validate_UpdateDataSource_602456, base: "/",
    url: url_UpdateDataSource_602457, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDataSource_602440 = ref object of OpenApiRestCall_601389
proc url_DescribeDataSource_602442(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeDataSource_602441(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Describes a data source.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DataSourceId: JString (required)
  ##               : The ID of the data source. This ID is unique per AWS Region for each AWS account.
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `DataSourceId` field"
  var valid_602443 = path.getOrDefault("DataSourceId")
  valid_602443 = validateParameter(valid_602443, JString, required = true,
                                 default = nil)
  if valid_602443 != nil:
    section.add "DataSourceId", valid_602443
  var valid_602444 = path.getOrDefault("AwsAccountId")
  valid_602444 = validateParameter(valid_602444, JString, required = true,
                                 default = nil)
  if valid_602444 != nil:
    section.add "AwsAccountId", valid_602444
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602445 = header.getOrDefault("X-Amz-Signature")
  valid_602445 = validateParameter(valid_602445, JString, required = false,
                                 default = nil)
  if valid_602445 != nil:
    section.add "X-Amz-Signature", valid_602445
  var valid_602446 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602446 = validateParameter(valid_602446, JString, required = false,
                                 default = nil)
  if valid_602446 != nil:
    section.add "X-Amz-Content-Sha256", valid_602446
  var valid_602447 = header.getOrDefault("X-Amz-Date")
  valid_602447 = validateParameter(valid_602447, JString, required = false,
                                 default = nil)
  if valid_602447 != nil:
    section.add "X-Amz-Date", valid_602447
  var valid_602448 = header.getOrDefault("X-Amz-Credential")
  valid_602448 = validateParameter(valid_602448, JString, required = false,
                                 default = nil)
  if valid_602448 != nil:
    section.add "X-Amz-Credential", valid_602448
  var valid_602449 = header.getOrDefault("X-Amz-Security-Token")
  valid_602449 = validateParameter(valid_602449, JString, required = false,
                                 default = nil)
  if valid_602449 != nil:
    section.add "X-Amz-Security-Token", valid_602449
  var valid_602450 = header.getOrDefault("X-Amz-Algorithm")
  valid_602450 = validateParameter(valid_602450, JString, required = false,
                                 default = nil)
  if valid_602450 != nil:
    section.add "X-Amz-Algorithm", valid_602450
  var valid_602451 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602451 = validateParameter(valid_602451, JString, required = false,
                                 default = nil)
  if valid_602451 != nil:
    section.add "X-Amz-SignedHeaders", valid_602451
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602452: Call_DescribeDataSource_602440; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a data source.
  ## 
  let valid = call_602452.validator(path, query, header, formData, body)
  let scheme = call_602452.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602452.url(scheme.get, call_602452.host, call_602452.base,
                         call_602452.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602452, url, valid)

proc call*(call_602453: Call_DescribeDataSource_602440; DataSourceId: string;
          AwsAccountId: string): Recallable =
  ## describeDataSource
  ## Describes a data source.
  ##   DataSourceId: string (required)
  ##               : The ID of the data source. This ID is unique per AWS Region for each AWS account.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  var path_602454 = newJObject()
  add(path_602454, "DataSourceId", newJString(DataSourceId))
  add(path_602454, "AwsAccountId", newJString(AwsAccountId))
  result = call_602453.call(path_602454, nil, nil, nil, nil)

var describeDataSource* = Call_DescribeDataSource_602440(
    name: "describeDataSource", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sources/{DataSourceId}",
    validator: validate_DescribeDataSource_602441, base: "/",
    url: url_DescribeDataSource_602442, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDataSource_602472 = ref object of OpenApiRestCall_601389
proc url_DeleteDataSource_602474(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDataSource_602473(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Deletes the data source permanently. This action breaks all the datasets that reference the deleted data source.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DataSourceId: JString (required)
  ##               : The ID of the data source. This ID is unique per AWS Region for each AWS account.
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `DataSourceId` field"
  var valid_602475 = path.getOrDefault("DataSourceId")
  valid_602475 = validateParameter(valid_602475, JString, required = true,
                                 default = nil)
  if valid_602475 != nil:
    section.add "DataSourceId", valid_602475
  var valid_602476 = path.getOrDefault("AwsAccountId")
  valid_602476 = validateParameter(valid_602476, JString, required = true,
                                 default = nil)
  if valid_602476 != nil:
    section.add "AwsAccountId", valid_602476
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602477 = header.getOrDefault("X-Amz-Signature")
  valid_602477 = validateParameter(valid_602477, JString, required = false,
                                 default = nil)
  if valid_602477 != nil:
    section.add "X-Amz-Signature", valid_602477
  var valid_602478 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602478 = validateParameter(valid_602478, JString, required = false,
                                 default = nil)
  if valid_602478 != nil:
    section.add "X-Amz-Content-Sha256", valid_602478
  var valid_602479 = header.getOrDefault("X-Amz-Date")
  valid_602479 = validateParameter(valid_602479, JString, required = false,
                                 default = nil)
  if valid_602479 != nil:
    section.add "X-Amz-Date", valid_602479
  var valid_602480 = header.getOrDefault("X-Amz-Credential")
  valid_602480 = validateParameter(valid_602480, JString, required = false,
                                 default = nil)
  if valid_602480 != nil:
    section.add "X-Amz-Credential", valid_602480
  var valid_602481 = header.getOrDefault("X-Amz-Security-Token")
  valid_602481 = validateParameter(valid_602481, JString, required = false,
                                 default = nil)
  if valid_602481 != nil:
    section.add "X-Amz-Security-Token", valid_602481
  var valid_602482 = header.getOrDefault("X-Amz-Algorithm")
  valid_602482 = validateParameter(valid_602482, JString, required = false,
                                 default = nil)
  if valid_602482 != nil:
    section.add "X-Amz-Algorithm", valid_602482
  var valid_602483 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602483 = validateParameter(valid_602483, JString, required = false,
                                 default = nil)
  if valid_602483 != nil:
    section.add "X-Amz-SignedHeaders", valid_602483
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602484: Call_DeleteDataSource_602472; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the data source permanently. This action breaks all the datasets that reference the deleted data source.
  ## 
  let valid = call_602484.validator(path, query, header, formData, body)
  let scheme = call_602484.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602484.url(scheme.get, call_602484.host, call_602484.base,
                         call_602484.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602484, url, valid)

proc call*(call_602485: Call_DeleteDataSource_602472; DataSourceId: string;
          AwsAccountId: string): Recallable =
  ## deleteDataSource
  ## Deletes the data source permanently. This action breaks all the datasets that reference the deleted data source.
  ##   DataSourceId: string (required)
  ##               : The ID of the data source. This ID is unique per AWS Region for each AWS account.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  var path_602486 = newJObject()
  add(path_602486, "DataSourceId", newJString(DataSourceId))
  add(path_602486, "AwsAccountId", newJString(AwsAccountId))
  result = call_602485.call(path_602486, nil, nil, nil, nil)

var deleteDataSource* = Call_DeleteDataSource_602472(name: "deleteDataSource",
    meth: HttpMethod.HttpDelete, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sources/{DataSourceId}",
    validator: validate_DeleteDataSource_602473, base: "/",
    url: url_DeleteDataSource_602474, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGroup_602503 = ref object of OpenApiRestCall_601389
proc url_UpdateGroup_602505(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateGroup_602504(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_602506 = path.getOrDefault("GroupName")
  valid_602506 = validateParameter(valid_602506, JString, required = true,
                                 default = nil)
  if valid_602506 != nil:
    section.add "GroupName", valid_602506
  var valid_602507 = path.getOrDefault("AwsAccountId")
  valid_602507 = validateParameter(valid_602507, JString, required = true,
                                 default = nil)
  if valid_602507 != nil:
    section.add "AwsAccountId", valid_602507
  var valid_602508 = path.getOrDefault("Namespace")
  valid_602508 = validateParameter(valid_602508, JString, required = true,
                                 default = nil)
  if valid_602508 != nil:
    section.add "Namespace", valid_602508
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602509 = header.getOrDefault("X-Amz-Signature")
  valid_602509 = validateParameter(valid_602509, JString, required = false,
                                 default = nil)
  if valid_602509 != nil:
    section.add "X-Amz-Signature", valid_602509
  var valid_602510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602510 = validateParameter(valid_602510, JString, required = false,
                                 default = nil)
  if valid_602510 != nil:
    section.add "X-Amz-Content-Sha256", valid_602510
  var valid_602511 = header.getOrDefault("X-Amz-Date")
  valid_602511 = validateParameter(valid_602511, JString, required = false,
                                 default = nil)
  if valid_602511 != nil:
    section.add "X-Amz-Date", valid_602511
  var valid_602512 = header.getOrDefault("X-Amz-Credential")
  valid_602512 = validateParameter(valid_602512, JString, required = false,
                                 default = nil)
  if valid_602512 != nil:
    section.add "X-Amz-Credential", valid_602512
  var valid_602513 = header.getOrDefault("X-Amz-Security-Token")
  valid_602513 = validateParameter(valid_602513, JString, required = false,
                                 default = nil)
  if valid_602513 != nil:
    section.add "X-Amz-Security-Token", valid_602513
  var valid_602514 = header.getOrDefault("X-Amz-Algorithm")
  valid_602514 = validateParameter(valid_602514, JString, required = false,
                                 default = nil)
  if valid_602514 != nil:
    section.add "X-Amz-Algorithm", valid_602514
  var valid_602515 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602515 = validateParameter(valid_602515, JString, required = false,
                                 default = nil)
  if valid_602515 != nil:
    section.add "X-Amz-SignedHeaders", valid_602515
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602517: Call_UpdateGroup_602503; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes a group description. 
  ## 
  let valid = call_602517.validator(path, query, header, formData, body)
  let scheme = call_602517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602517.url(scheme.get, call_602517.host, call_602517.base,
                         call_602517.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602517, url, valid)

proc call*(call_602518: Call_UpdateGroup_602503; GroupName: string;
          AwsAccountId: string; Namespace: string; body: JsonNode): Recallable =
  ## updateGroup
  ## Changes a group description. 
  ##   GroupName: string (required)
  ##            : The name of the group that you want to update.
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   body: JObject (required)
  var path_602519 = newJObject()
  var body_602520 = newJObject()
  add(path_602519, "GroupName", newJString(GroupName))
  add(path_602519, "AwsAccountId", newJString(AwsAccountId))
  add(path_602519, "Namespace", newJString(Namespace))
  if body != nil:
    body_602520 = body
  result = call_602518.call(path_602519, nil, nil, nil, body_602520)

var updateGroup* = Call_UpdateGroup_602503(name: "updateGroup",
                                        meth: HttpMethod.HttpPut,
                                        host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}",
                                        validator: validate_UpdateGroup_602504,
                                        base: "/", url: url_UpdateGroup_602505,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeGroup_602487 = ref object of OpenApiRestCall_601389
proc url_DescribeGroup_602489(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeGroup_602488(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_602490 = path.getOrDefault("GroupName")
  valid_602490 = validateParameter(valid_602490, JString, required = true,
                                 default = nil)
  if valid_602490 != nil:
    section.add "GroupName", valid_602490
  var valid_602491 = path.getOrDefault("AwsAccountId")
  valid_602491 = validateParameter(valid_602491, JString, required = true,
                                 default = nil)
  if valid_602491 != nil:
    section.add "AwsAccountId", valid_602491
  var valid_602492 = path.getOrDefault("Namespace")
  valid_602492 = validateParameter(valid_602492, JString, required = true,
                                 default = nil)
  if valid_602492 != nil:
    section.add "Namespace", valid_602492
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602493 = header.getOrDefault("X-Amz-Signature")
  valid_602493 = validateParameter(valid_602493, JString, required = false,
                                 default = nil)
  if valid_602493 != nil:
    section.add "X-Amz-Signature", valid_602493
  var valid_602494 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602494 = validateParameter(valid_602494, JString, required = false,
                                 default = nil)
  if valid_602494 != nil:
    section.add "X-Amz-Content-Sha256", valid_602494
  var valid_602495 = header.getOrDefault("X-Amz-Date")
  valid_602495 = validateParameter(valid_602495, JString, required = false,
                                 default = nil)
  if valid_602495 != nil:
    section.add "X-Amz-Date", valid_602495
  var valid_602496 = header.getOrDefault("X-Amz-Credential")
  valid_602496 = validateParameter(valid_602496, JString, required = false,
                                 default = nil)
  if valid_602496 != nil:
    section.add "X-Amz-Credential", valid_602496
  var valid_602497 = header.getOrDefault("X-Amz-Security-Token")
  valid_602497 = validateParameter(valid_602497, JString, required = false,
                                 default = nil)
  if valid_602497 != nil:
    section.add "X-Amz-Security-Token", valid_602497
  var valid_602498 = header.getOrDefault("X-Amz-Algorithm")
  valid_602498 = validateParameter(valid_602498, JString, required = false,
                                 default = nil)
  if valid_602498 != nil:
    section.add "X-Amz-Algorithm", valid_602498
  var valid_602499 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602499 = validateParameter(valid_602499, JString, required = false,
                                 default = nil)
  if valid_602499 != nil:
    section.add "X-Amz-SignedHeaders", valid_602499
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602500: Call_DescribeGroup_602487; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an Amazon QuickSight group's description and Amazon Resource Name (ARN). 
  ## 
  let valid = call_602500.validator(path, query, header, formData, body)
  let scheme = call_602500.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602500.url(scheme.get, call_602500.host, call_602500.base,
                         call_602500.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602500, url, valid)

proc call*(call_602501: Call_DescribeGroup_602487; GroupName: string;
          AwsAccountId: string; Namespace: string): Recallable =
  ## describeGroup
  ## Returns an Amazon QuickSight group's description and Amazon Resource Name (ARN). 
  ##   GroupName: string (required)
  ##            : The name of the group that you want to describe.
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  var path_602502 = newJObject()
  add(path_602502, "GroupName", newJString(GroupName))
  add(path_602502, "AwsAccountId", newJString(AwsAccountId))
  add(path_602502, "Namespace", newJString(Namespace))
  result = call_602501.call(path_602502, nil, nil, nil, nil)

var describeGroup* = Call_DescribeGroup_602487(name: "describeGroup",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}",
    validator: validate_DescribeGroup_602488, base: "/", url: url_DescribeGroup_602489,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGroup_602521 = ref object of OpenApiRestCall_601389
proc url_DeleteGroup_602523(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteGroup_602522(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_602524 = path.getOrDefault("GroupName")
  valid_602524 = validateParameter(valid_602524, JString, required = true,
                                 default = nil)
  if valid_602524 != nil:
    section.add "GroupName", valid_602524
  var valid_602525 = path.getOrDefault("AwsAccountId")
  valid_602525 = validateParameter(valid_602525, JString, required = true,
                                 default = nil)
  if valid_602525 != nil:
    section.add "AwsAccountId", valid_602525
  var valid_602526 = path.getOrDefault("Namespace")
  valid_602526 = validateParameter(valid_602526, JString, required = true,
                                 default = nil)
  if valid_602526 != nil:
    section.add "Namespace", valid_602526
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602527 = header.getOrDefault("X-Amz-Signature")
  valid_602527 = validateParameter(valid_602527, JString, required = false,
                                 default = nil)
  if valid_602527 != nil:
    section.add "X-Amz-Signature", valid_602527
  var valid_602528 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602528 = validateParameter(valid_602528, JString, required = false,
                                 default = nil)
  if valid_602528 != nil:
    section.add "X-Amz-Content-Sha256", valid_602528
  var valid_602529 = header.getOrDefault("X-Amz-Date")
  valid_602529 = validateParameter(valid_602529, JString, required = false,
                                 default = nil)
  if valid_602529 != nil:
    section.add "X-Amz-Date", valid_602529
  var valid_602530 = header.getOrDefault("X-Amz-Credential")
  valid_602530 = validateParameter(valid_602530, JString, required = false,
                                 default = nil)
  if valid_602530 != nil:
    section.add "X-Amz-Credential", valid_602530
  var valid_602531 = header.getOrDefault("X-Amz-Security-Token")
  valid_602531 = validateParameter(valid_602531, JString, required = false,
                                 default = nil)
  if valid_602531 != nil:
    section.add "X-Amz-Security-Token", valid_602531
  var valid_602532 = header.getOrDefault("X-Amz-Algorithm")
  valid_602532 = validateParameter(valid_602532, JString, required = false,
                                 default = nil)
  if valid_602532 != nil:
    section.add "X-Amz-Algorithm", valid_602532
  var valid_602533 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602533 = validateParameter(valid_602533, JString, required = false,
                                 default = nil)
  if valid_602533 != nil:
    section.add "X-Amz-SignedHeaders", valid_602533
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602534: Call_DeleteGroup_602521; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a user group from Amazon QuickSight. 
  ## 
  let valid = call_602534.validator(path, query, header, formData, body)
  let scheme = call_602534.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602534.url(scheme.get, call_602534.host, call_602534.base,
                         call_602534.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602534, url, valid)

proc call*(call_602535: Call_DeleteGroup_602521; GroupName: string;
          AwsAccountId: string; Namespace: string): Recallable =
  ## deleteGroup
  ## Removes a user group from Amazon QuickSight. 
  ##   GroupName: string (required)
  ##            : The name of the group that you want to delete.
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  var path_602536 = newJObject()
  add(path_602536, "GroupName", newJString(GroupName))
  add(path_602536, "AwsAccountId", newJString(AwsAccountId))
  add(path_602536, "Namespace", newJString(Namespace))
  result = call_602535.call(path_602536, nil, nil, nil, nil)

var deleteGroup* = Call_DeleteGroup_602521(name: "deleteGroup",
                                        meth: HttpMethod.HttpDelete,
                                        host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}",
                                        validator: validate_DeleteGroup_602522,
                                        base: "/", url: url_DeleteGroup_602523,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIAMPolicyAssignment_602537 = ref object of OpenApiRestCall_601389
proc url_DeleteIAMPolicyAssignment_602539(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteIAMPolicyAssignment_602538(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an existing IAM policy assignment.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID where you want to delete the IAM policy assignment.
  ##   Namespace: JString (required)
  ##            : The namespace that contains the assignment.
  ##   AssignmentName: JString (required)
  ##                 : The name of the assignment. 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_602540 = path.getOrDefault("AwsAccountId")
  valid_602540 = validateParameter(valid_602540, JString, required = true,
                                 default = nil)
  if valid_602540 != nil:
    section.add "AwsAccountId", valid_602540
  var valid_602541 = path.getOrDefault("Namespace")
  valid_602541 = validateParameter(valid_602541, JString, required = true,
                                 default = nil)
  if valid_602541 != nil:
    section.add "Namespace", valid_602541
  var valid_602542 = path.getOrDefault("AssignmentName")
  valid_602542 = validateParameter(valid_602542, JString, required = true,
                                 default = nil)
  if valid_602542 != nil:
    section.add "AssignmentName", valid_602542
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602543 = header.getOrDefault("X-Amz-Signature")
  valid_602543 = validateParameter(valid_602543, JString, required = false,
                                 default = nil)
  if valid_602543 != nil:
    section.add "X-Amz-Signature", valid_602543
  var valid_602544 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602544 = validateParameter(valid_602544, JString, required = false,
                                 default = nil)
  if valid_602544 != nil:
    section.add "X-Amz-Content-Sha256", valid_602544
  var valid_602545 = header.getOrDefault("X-Amz-Date")
  valid_602545 = validateParameter(valid_602545, JString, required = false,
                                 default = nil)
  if valid_602545 != nil:
    section.add "X-Amz-Date", valid_602545
  var valid_602546 = header.getOrDefault("X-Amz-Credential")
  valid_602546 = validateParameter(valid_602546, JString, required = false,
                                 default = nil)
  if valid_602546 != nil:
    section.add "X-Amz-Credential", valid_602546
  var valid_602547 = header.getOrDefault("X-Amz-Security-Token")
  valid_602547 = validateParameter(valid_602547, JString, required = false,
                                 default = nil)
  if valid_602547 != nil:
    section.add "X-Amz-Security-Token", valid_602547
  var valid_602548 = header.getOrDefault("X-Amz-Algorithm")
  valid_602548 = validateParameter(valid_602548, JString, required = false,
                                 default = nil)
  if valid_602548 != nil:
    section.add "X-Amz-Algorithm", valid_602548
  var valid_602549 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602549 = validateParameter(valid_602549, JString, required = false,
                                 default = nil)
  if valid_602549 != nil:
    section.add "X-Amz-SignedHeaders", valid_602549
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602550: Call_DeleteIAMPolicyAssignment_602537; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing IAM policy assignment.
  ## 
  let valid = call_602550.validator(path, query, header, formData, body)
  let scheme = call_602550.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602550.url(scheme.get, call_602550.host, call_602550.base,
                         call_602550.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602550, url, valid)

proc call*(call_602551: Call_DeleteIAMPolicyAssignment_602537;
          AwsAccountId: string; Namespace: string; AssignmentName: string): Recallable =
  ## deleteIAMPolicyAssignment
  ## Deletes an existing IAM policy assignment.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID where you want to delete the IAM policy assignment.
  ##   Namespace: string (required)
  ##            : The namespace that contains the assignment.
  ##   AssignmentName: string (required)
  ##                 : The name of the assignment. 
  var path_602552 = newJObject()
  add(path_602552, "AwsAccountId", newJString(AwsAccountId))
  add(path_602552, "Namespace", newJString(Namespace))
  add(path_602552, "AssignmentName", newJString(AssignmentName))
  result = call_602551.call(path_602552, nil, nil, nil, nil)

var deleteIAMPolicyAssignment* = Call_DeleteIAMPolicyAssignment_602537(
    name: "deleteIAMPolicyAssignment", meth: HttpMethod.HttpDelete,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespace/{Namespace}/iam-policy-assignments/{AssignmentName}",
    validator: validate_DeleteIAMPolicyAssignment_602538, base: "/",
    url: url_DeleteIAMPolicyAssignment_602539,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUser_602569 = ref object of OpenApiRestCall_601389
proc url_UpdateUser_602571(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateUser_602570(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an Amazon QuickSight user.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   UserName: JString (required)
  ##           : The Amazon QuickSight user name that you want to update.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_602572 = path.getOrDefault("AwsAccountId")
  valid_602572 = validateParameter(valid_602572, JString, required = true,
                                 default = nil)
  if valid_602572 != nil:
    section.add "AwsAccountId", valid_602572
  var valid_602573 = path.getOrDefault("Namespace")
  valid_602573 = validateParameter(valid_602573, JString, required = true,
                                 default = nil)
  if valid_602573 != nil:
    section.add "Namespace", valid_602573
  var valid_602574 = path.getOrDefault("UserName")
  valid_602574 = validateParameter(valid_602574, JString, required = true,
                                 default = nil)
  if valid_602574 != nil:
    section.add "UserName", valid_602574
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602575 = header.getOrDefault("X-Amz-Signature")
  valid_602575 = validateParameter(valid_602575, JString, required = false,
                                 default = nil)
  if valid_602575 != nil:
    section.add "X-Amz-Signature", valid_602575
  var valid_602576 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602576 = validateParameter(valid_602576, JString, required = false,
                                 default = nil)
  if valid_602576 != nil:
    section.add "X-Amz-Content-Sha256", valid_602576
  var valid_602577 = header.getOrDefault("X-Amz-Date")
  valid_602577 = validateParameter(valid_602577, JString, required = false,
                                 default = nil)
  if valid_602577 != nil:
    section.add "X-Amz-Date", valid_602577
  var valid_602578 = header.getOrDefault("X-Amz-Credential")
  valid_602578 = validateParameter(valid_602578, JString, required = false,
                                 default = nil)
  if valid_602578 != nil:
    section.add "X-Amz-Credential", valid_602578
  var valid_602579 = header.getOrDefault("X-Amz-Security-Token")
  valid_602579 = validateParameter(valid_602579, JString, required = false,
                                 default = nil)
  if valid_602579 != nil:
    section.add "X-Amz-Security-Token", valid_602579
  var valid_602580 = header.getOrDefault("X-Amz-Algorithm")
  valid_602580 = validateParameter(valid_602580, JString, required = false,
                                 default = nil)
  if valid_602580 != nil:
    section.add "X-Amz-Algorithm", valid_602580
  var valid_602581 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602581 = validateParameter(valid_602581, JString, required = false,
                                 default = nil)
  if valid_602581 != nil:
    section.add "X-Amz-SignedHeaders", valid_602581
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602583: Call_UpdateUser_602569; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an Amazon QuickSight user.
  ## 
  let valid = call_602583.validator(path, query, header, formData, body)
  let scheme = call_602583.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602583.url(scheme.get, call_602583.host, call_602583.base,
                         call_602583.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602583, url, valid)

proc call*(call_602584: Call_UpdateUser_602569; AwsAccountId: string;
          Namespace: string; UserName: string; body: JsonNode): Recallable =
  ## updateUser
  ## Updates an Amazon QuickSight user.
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   UserName: string (required)
  ##           : The Amazon QuickSight user name that you want to update.
  ##   body: JObject (required)
  var path_602585 = newJObject()
  var body_602586 = newJObject()
  add(path_602585, "AwsAccountId", newJString(AwsAccountId))
  add(path_602585, "Namespace", newJString(Namespace))
  add(path_602585, "UserName", newJString(UserName))
  if body != nil:
    body_602586 = body
  result = call_602584.call(path_602585, nil, nil, nil, body_602586)

var updateUser* = Call_UpdateUser_602569(name: "updateUser",
                                      meth: HttpMethod.HttpPut,
                                      host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}",
                                      validator: validate_UpdateUser_602570,
                                      base: "/", url: url_UpdateUser_602571,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUser_602553 = ref object of OpenApiRestCall_601389
proc url_DescribeUser_602555(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeUser_602554(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about a user, given the user name. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   UserName: JString (required)
  ##           : The name of the user that you want to describe.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_602556 = path.getOrDefault("AwsAccountId")
  valid_602556 = validateParameter(valid_602556, JString, required = true,
                                 default = nil)
  if valid_602556 != nil:
    section.add "AwsAccountId", valid_602556
  var valid_602557 = path.getOrDefault("Namespace")
  valid_602557 = validateParameter(valid_602557, JString, required = true,
                                 default = nil)
  if valid_602557 != nil:
    section.add "Namespace", valid_602557
  var valid_602558 = path.getOrDefault("UserName")
  valid_602558 = validateParameter(valid_602558, JString, required = true,
                                 default = nil)
  if valid_602558 != nil:
    section.add "UserName", valid_602558
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602559 = header.getOrDefault("X-Amz-Signature")
  valid_602559 = validateParameter(valid_602559, JString, required = false,
                                 default = nil)
  if valid_602559 != nil:
    section.add "X-Amz-Signature", valid_602559
  var valid_602560 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602560 = validateParameter(valid_602560, JString, required = false,
                                 default = nil)
  if valid_602560 != nil:
    section.add "X-Amz-Content-Sha256", valid_602560
  var valid_602561 = header.getOrDefault("X-Amz-Date")
  valid_602561 = validateParameter(valid_602561, JString, required = false,
                                 default = nil)
  if valid_602561 != nil:
    section.add "X-Amz-Date", valid_602561
  var valid_602562 = header.getOrDefault("X-Amz-Credential")
  valid_602562 = validateParameter(valid_602562, JString, required = false,
                                 default = nil)
  if valid_602562 != nil:
    section.add "X-Amz-Credential", valid_602562
  var valid_602563 = header.getOrDefault("X-Amz-Security-Token")
  valid_602563 = validateParameter(valid_602563, JString, required = false,
                                 default = nil)
  if valid_602563 != nil:
    section.add "X-Amz-Security-Token", valid_602563
  var valid_602564 = header.getOrDefault("X-Amz-Algorithm")
  valid_602564 = validateParameter(valid_602564, JString, required = false,
                                 default = nil)
  if valid_602564 != nil:
    section.add "X-Amz-Algorithm", valid_602564
  var valid_602565 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602565 = validateParameter(valid_602565, JString, required = false,
                                 default = nil)
  if valid_602565 != nil:
    section.add "X-Amz-SignedHeaders", valid_602565
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602566: Call_DescribeUser_602553; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a user, given the user name. 
  ## 
  let valid = call_602566.validator(path, query, header, formData, body)
  let scheme = call_602566.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602566.url(scheme.get, call_602566.host, call_602566.base,
                         call_602566.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602566, url, valid)

proc call*(call_602567: Call_DescribeUser_602553; AwsAccountId: string;
          Namespace: string; UserName: string): Recallable =
  ## describeUser
  ## Returns information about a user, given the user name. 
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   UserName: string (required)
  ##           : The name of the user that you want to describe.
  var path_602568 = newJObject()
  add(path_602568, "AwsAccountId", newJString(AwsAccountId))
  add(path_602568, "Namespace", newJString(Namespace))
  add(path_602568, "UserName", newJString(UserName))
  result = call_602567.call(path_602568, nil, nil, nil, nil)

var describeUser* = Call_DescribeUser_602553(name: "describeUser",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}",
    validator: validate_DescribeUser_602554, base: "/", url: url_DescribeUser_602555,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_602587 = ref object of OpenApiRestCall_601389
proc url_DeleteUser_602589(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteUser_602588(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the Amazon QuickSight user that is associated with the identity of the AWS Identity and Access Management (IAM) user or role that's making the call. The IAM user isn't deleted as a result of this call. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   UserName: JString (required)
  ##           : The name of the user that you want to delete.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_602590 = path.getOrDefault("AwsAccountId")
  valid_602590 = validateParameter(valid_602590, JString, required = true,
                                 default = nil)
  if valid_602590 != nil:
    section.add "AwsAccountId", valid_602590
  var valid_602591 = path.getOrDefault("Namespace")
  valid_602591 = validateParameter(valid_602591, JString, required = true,
                                 default = nil)
  if valid_602591 != nil:
    section.add "Namespace", valid_602591
  var valid_602592 = path.getOrDefault("UserName")
  valid_602592 = validateParameter(valid_602592, JString, required = true,
                                 default = nil)
  if valid_602592 != nil:
    section.add "UserName", valid_602592
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602593 = header.getOrDefault("X-Amz-Signature")
  valid_602593 = validateParameter(valid_602593, JString, required = false,
                                 default = nil)
  if valid_602593 != nil:
    section.add "X-Amz-Signature", valid_602593
  var valid_602594 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602594 = validateParameter(valid_602594, JString, required = false,
                                 default = nil)
  if valid_602594 != nil:
    section.add "X-Amz-Content-Sha256", valid_602594
  var valid_602595 = header.getOrDefault("X-Amz-Date")
  valid_602595 = validateParameter(valid_602595, JString, required = false,
                                 default = nil)
  if valid_602595 != nil:
    section.add "X-Amz-Date", valid_602595
  var valid_602596 = header.getOrDefault("X-Amz-Credential")
  valid_602596 = validateParameter(valid_602596, JString, required = false,
                                 default = nil)
  if valid_602596 != nil:
    section.add "X-Amz-Credential", valid_602596
  var valid_602597 = header.getOrDefault("X-Amz-Security-Token")
  valid_602597 = validateParameter(valid_602597, JString, required = false,
                                 default = nil)
  if valid_602597 != nil:
    section.add "X-Amz-Security-Token", valid_602597
  var valid_602598 = header.getOrDefault("X-Amz-Algorithm")
  valid_602598 = validateParameter(valid_602598, JString, required = false,
                                 default = nil)
  if valid_602598 != nil:
    section.add "X-Amz-Algorithm", valid_602598
  var valid_602599 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602599 = validateParameter(valid_602599, JString, required = false,
                                 default = nil)
  if valid_602599 != nil:
    section.add "X-Amz-SignedHeaders", valid_602599
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602600: Call_DeleteUser_602587; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the Amazon QuickSight user that is associated with the identity of the AWS Identity and Access Management (IAM) user or role that's making the call. The IAM user isn't deleted as a result of this call. 
  ## 
  let valid = call_602600.validator(path, query, header, formData, body)
  let scheme = call_602600.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602600.url(scheme.get, call_602600.host, call_602600.base,
                         call_602600.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602600, url, valid)

proc call*(call_602601: Call_DeleteUser_602587; AwsAccountId: string;
          Namespace: string; UserName: string): Recallable =
  ## deleteUser
  ## Deletes the Amazon QuickSight user that is associated with the identity of the AWS Identity and Access Management (IAM) user or role that's making the call. The IAM user isn't deleted as a result of this call. 
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   UserName: string (required)
  ##           : The name of the user that you want to delete.
  var path_602602 = newJObject()
  add(path_602602, "AwsAccountId", newJString(AwsAccountId))
  add(path_602602, "Namespace", newJString(Namespace))
  add(path_602602, "UserName", newJString(UserName))
  result = call_602601.call(path_602602, nil, nil, nil, nil)

var deleteUser* = Call_DeleteUser_602587(name: "deleteUser",
                                      meth: HttpMethod.HttpDelete,
                                      host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}",
                                      validator: validate_DeleteUser_602588,
                                      base: "/", url: url_DeleteUser_602589,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserByPrincipalId_602603 = ref object of OpenApiRestCall_601389
proc url_DeleteUserByPrincipalId_602605(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteUserByPrincipalId_602604(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a user identified by its principal ID. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   PrincipalId: JString (required)
  ##              : The principal ID of the user.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_602606 = path.getOrDefault("AwsAccountId")
  valid_602606 = validateParameter(valid_602606, JString, required = true,
                                 default = nil)
  if valid_602606 != nil:
    section.add "AwsAccountId", valid_602606
  var valid_602607 = path.getOrDefault("Namespace")
  valid_602607 = validateParameter(valid_602607, JString, required = true,
                                 default = nil)
  if valid_602607 != nil:
    section.add "Namespace", valid_602607
  var valid_602608 = path.getOrDefault("PrincipalId")
  valid_602608 = validateParameter(valid_602608, JString, required = true,
                                 default = nil)
  if valid_602608 != nil:
    section.add "PrincipalId", valid_602608
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602609 = header.getOrDefault("X-Amz-Signature")
  valid_602609 = validateParameter(valid_602609, JString, required = false,
                                 default = nil)
  if valid_602609 != nil:
    section.add "X-Amz-Signature", valid_602609
  var valid_602610 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602610 = validateParameter(valid_602610, JString, required = false,
                                 default = nil)
  if valid_602610 != nil:
    section.add "X-Amz-Content-Sha256", valid_602610
  var valid_602611 = header.getOrDefault("X-Amz-Date")
  valid_602611 = validateParameter(valid_602611, JString, required = false,
                                 default = nil)
  if valid_602611 != nil:
    section.add "X-Amz-Date", valid_602611
  var valid_602612 = header.getOrDefault("X-Amz-Credential")
  valid_602612 = validateParameter(valid_602612, JString, required = false,
                                 default = nil)
  if valid_602612 != nil:
    section.add "X-Amz-Credential", valid_602612
  var valid_602613 = header.getOrDefault("X-Amz-Security-Token")
  valid_602613 = validateParameter(valid_602613, JString, required = false,
                                 default = nil)
  if valid_602613 != nil:
    section.add "X-Amz-Security-Token", valid_602613
  var valid_602614 = header.getOrDefault("X-Amz-Algorithm")
  valid_602614 = validateParameter(valid_602614, JString, required = false,
                                 default = nil)
  if valid_602614 != nil:
    section.add "X-Amz-Algorithm", valid_602614
  var valid_602615 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602615 = validateParameter(valid_602615, JString, required = false,
                                 default = nil)
  if valid_602615 != nil:
    section.add "X-Amz-SignedHeaders", valid_602615
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602616: Call_DeleteUserByPrincipalId_602603; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a user identified by its principal ID. 
  ## 
  let valid = call_602616.validator(path, query, header, formData, body)
  let scheme = call_602616.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602616.url(scheme.get, call_602616.host, call_602616.base,
                         call_602616.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602616, url, valid)

proc call*(call_602617: Call_DeleteUserByPrincipalId_602603; AwsAccountId: string;
          Namespace: string; PrincipalId: string): Recallable =
  ## deleteUserByPrincipalId
  ## Deletes a user identified by its principal ID. 
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   PrincipalId: string (required)
  ##              : The principal ID of the user.
  var path_602618 = newJObject()
  add(path_602618, "AwsAccountId", newJString(AwsAccountId))
  add(path_602618, "Namespace", newJString(Namespace))
  add(path_602618, "PrincipalId", newJString(PrincipalId))
  result = call_602617.call(path_602618, nil, nil, nil, nil)

var deleteUserByPrincipalId* = Call_DeleteUserByPrincipalId_602603(
    name: "deleteUserByPrincipalId", meth: HttpMethod.HttpDelete,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/user-principals/{PrincipalId}",
    validator: validate_DeleteUserByPrincipalId_602604, base: "/",
    url: url_DeleteUserByPrincipalId_602605, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDashboardPermissions_602634 = ref object of OpenApiRestCall_601389
proc url_UpdateDashboardPermissions_602636(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDashboardPermissions_602635(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_602637 = path.getOrDefault("AwsAccountId")
  valid_602637 = validateParameter(valid_602637, JString, required = true,
                                 default = nil)
  if valid_602637 != nil:
    section.add "AwsAccountId", valid_602637
  var valid_602638 = path.getOrDefault("DashboardId")
  valid_602638 = validateParameter(valid_602638, JString, required = true,
                                 default = nil)
  if valid_602638 != nil:
    section.add "DashboardId", valid_602638
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602639 = header.getOrDefault("X-Amz-Signature")
  valid_602639 = validateParameter(valid_602639, JString, required = false,
                                 default = nil)
  if valid_602639 != nil:
    section.add "X-Amz-Signature", valid_602639
  var valid_602640 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602640 = validateParameter(valid_602640, JString, required = false,
                                 default = nil)
  if valid_602640 != nil:
    section.add "X-Amz-Content-Sha256", valid_602640
  var valid_602641 = header.getOrDefault("X-Amz-Date")
  valid_602641 = validateParameter(valid_602641, JString, required = false,
                                 default = nil)
  if valid_602641 != nil:
    section.add "X-Amz-Date", valid_602641
  var valid_602642 = header.getOrDefault("X-Amz-Credential")
  valid_602642 = validateParameter(valid_602642, JString, required = false,
                                 default = nil)
  if valid_602642 != nil:
    section.add "X-Amz-Credential", valid_602642
  var valid_602643 = header.getOrDefault("X-Amz-Security-Token")
  valid_602643 = validateParameter(valid_602643, JString, required = false,
                                 default = nil)
  if valid_602643 != nil:
    section.add "X-Amz-Security-Token", valid_602643
  var valid_602644 = header.getOrDefault("X-Amz-Algorithm")
  valid_602644 = validateParameter(valid_602644, JString, required = false,
                                 default = nil)
  if valid_602644 != nil:
    section.add "X-Amz-Algorithm", valid_602644
  var valid_602645 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602645 = validateParameter(valid_602645, JString, required = false,
                                 default = nil)
  if valid_602645 != nil:
    section.add "X-Amz-SignedHeaders", valid_602645
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602647: Call_UpdateDashboardPermissions_602634; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates read and write permissions on a dashboard.
  ## 
  let valid = call_602647.validator(path, query, header, formData, body)
  let scheme = call_602647.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602647.url(scheme.get, call_602647.host, call_602647.base,
                         call_602647.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602647, url, valid)

proc call*(call_602648: Call_UpdateDashboardPermissions_602634;
          AwsAccountId: string; body: JsonNode; DashboardId: string): Recallable =
  ## updateDashboardPermissions
  ## Updates read and write permissions on a dashboard.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the dashboard whose permissions you're updating.
  ##   body: JObject (required)
  ##   DashboardId: string (required)
  ##              : The ID for the dashboard.
  var path_602649 = newJObject()
  var body_602650 = newJObject()
  add(path_602649, "AwsAccountId", newJString(AwsAccountId))
  if body != nil:
    body_602650 = body
  add(path_602649, "DashboardId", newJString(DashboardId))
  result = call_602648.call(path_602649, nil, nil, nil, body_602650)

var updateDashboardPermissions* = Call_UpdateDashboardPermissions_602634(
    name: "updateDashboardPermissions", meth: HttpMethod.HttpPut,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}/permissions",
    validator: validate_UpdateDashboardPermissions_602635, base: "/",
    url: url_UpdateDashboardPermissions_602636,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDashboardPermissions_602619 = ref object of OpenApiRestCall_601389
proc url_DescribeDashboardPermissions_602621(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeDashboardPermissions_602620(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_602622 = path.getOrDefault("AwsAccountId")
  valid_602622 = validateParameter(valid_602622, JString, required = true,
                                 default = nil)
  if valid_602622 != nil:
    section.add "AwsAccountId", valid_602622
  var valid_602623 = path.getOrDefault("DashboardId")
  valid_602623 = validateParameter(valid_602623, JString, required = true,
                                 default = nil)
  if valid_602623 != nil:
    section.add "DashboardId", valid_602623
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602624 = header.getOrDefault("X-Amz-Signature")
  valid_602624 = validateParameter(valid_602624, JString, required = false,
                                 default = nil)
  if valid_602624 != nil:
    section.add "X-Amz-Signature", valid_602624
  var valid_602625 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602625 = validateParameter(valid_602625, JString, required = false,
                                 default = nil)
  if valid_602625 != nil:
    section.add "X-Amz-Content-Sha256", valid_602625
  var valid_602626 = header.getOrDefault("X-Amz-Date")
  valid_602626 = validateParameter(valid_602626, JString, required = false,
                                 default = nil)
  if valid_602626 != nil:
    section.add "X-Amz-Date", valid_602626
  var valid_602627 = header.getOrDefault("X-Amz-Credential")
  valid_602627 = validateParameter(valid_602627, JString, required = false,
                                 default = nil)
  if valid_602627 != nil:
    section.add "X-Amz-Credential", valid_602627
  var valid_602628 = header.getOrDefault("X-Amz-Security-Token")
  valid_602628 = validateParameter(valid_602628, JString, required = false,
                                 default = nil)
  if valid_602628 != nil:
    section.add "X-Amz-Security-Token", valid_602628
  var valid_602629 = header.getOrDefault("X-Amz-Algorithm")
  valid_602629 = validateParameter(valid_602629, JString, required = false,
                                 default = nil)
  if valid_602629 != nil:
    section.add "X-Amz-Algorithm", valid_602629
  var valid_602630 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602630 = validateParameter(valid_602630, JString, required = false,
                                 default = nil)
  if valid_602630 != nil:
    section.add "X-Amz-SignedHeaders", valid_602630
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602631: Call_DescribeDashboardPermissions_602619; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes read and write permissions for a dashboard.
  ## 
  let valid = call_602631.validator(path, query, header, formData, body)
  let scheme = call_602631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602631.url(scheme.get, call_602631.host, call_602631.base,
                         call_602631.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602631, url, valid)

proc call*(call_602632: Call_DescribeDashboardPermissions_602619;
          AwsAccountId: string; DashboardId: string): Recallable =
  ## describeDashboardPermissions
  ## Describes read and write permissions for a dashboard.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the dashboard that you're describing permissions for.
  ##   DashboardId: string (required)
  ##              : The ID for the dashboard, also added to the IAM policy.
  var path_602633 = newJObject()
  add(path_602633, "AwsAccountId", newJString(AwsAccountId))
  add(path_602633, "DashboardId", newJString(DashboardId))
  result = call_602632.call(path_602633, nil, nil, nil, nil)

var describeDashboardPermissions* = Call_DescribeDashboardPermissions_602619(
    name: "describeDashboardPermissions", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}/permissions",
    validator: validate_DescribeDashboardPermissions_602620, base: "/",
    url: url_DescribeDashboardPermissions_602621,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDataSetPermissions_602666 = ref object of OpenApiRestCall_601389
proc url_UpdateDataSetPermissions_602668(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDataSetPermissions_602667(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_602669 = path.getOrDefault("AwsAccountId")
  valid_602669 = validateParameter(valid_602669, JString, required = true,
                                 default = nil)
  if valid_602669 != nil:
    section.add "AwsAccountId", valid_602669
  var valid_602670 = path.getOrDefault("DataSetId")
  valid_602670 = validateParameter(valid_602670, JString, required = true,
                                 default = nil)
  if valid_602670 != nil:
    section.add "DataSetId", valid_602670
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602671 = header.getOrDefault("X-Amz-Signature")
  valid_602671 = validateParameter(valid_602671, JString, required = false,
                                 default = nil)
  if valid_602671 != nil:
    section.add "X-Amz-Signature", valid_602671
  var valid_602672 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602672 = validateParameter(valid_602672, JString, required = false,
                                 default = nil)
  if valid_602672 != nil:
    section.add "X-Amz-Content-Sha256", valid_602672
  var valid_602673 = header.getOrDefault("X-Amz-Date")
  valid_602673 = validateParameter(valid_602673, JString, required = false,
                                 default = nil)
  if valid_602673 != nil:
    section.add "X-Amz-Date", valid_602673
  var valid_602674 = header.getOrDefault("X-Amz-Credential")
  valid_602674 = validateParameter(valid_602674, JString, required = false,
                                 default = nil)
  if valid_602674 != nil:
    section.add "X-Amz-Credential", valid_602674
  var valid_602675 = header.getOrDefault("X-Amz-Security-Token")
  valid_602675 = validateParameter(valid_602675, JString, required = false,
                                 default = nil)
  if valid_602675 != nil:
    section.add "X-Amz-Security-Token", valid_602675
  var valid_602676 = header.getOrDefault("X-Amz-Algorithm")
  valid_602676 = validateParameter(valid_602676, JString, required = false,
                                 default = nil)
  if valid_602676 != nil:
    section.add "X-Amz-Algorithm", valid_602676
  var valid_602677 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602677 = validateParameter(valid_602677, JString, required = false,
                                 default = nil)
  if valid_602677 != nil:
    section.add "X-Amz-SignedHeaders", valid_602677
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602679: Call_UpdateDataSetPermissions_602666; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the permissions on a dataset.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:dataset/data-set-id</code>.</p>
  ## 
  let valid = call_602679.validator(path, query, header, formData, body)
  let scheme = call_602679.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602679.url(scheme.get, call_602679.host, call_602679.base,
                         call_602679.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602679, url, valid)

proc call*(call_602680: Call_UpdateDataSetPermissions_602666; AwsAccountId: string;
          DataSetId: string; body: JsonNode): Recallable =
  ## updateDataSetPermissions
  ## <p>Updates the permissions on a dataset.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:dataset/data-set-id</code>.</p>
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSetId: string (required)
  ##            : The ID for the dataset whose permissions you want to update. This ID is unique per AWS Region for each AWS account.
  ##   body: JObject (required)
  var path_602681 = newJObject()
  var body_602682 = newJObject()
  add(path_602681, "AwsAccountId", newJString(AwsAccountId))
  add(path_602681, "DataSetId", newJString(DataSetId))
  if body != nil:
    body_602682 = body
  result = call_602680.call(path_602681, nil, nil, nil, body_602682)

var updateDataSetPermissions* = Call_UpdateDataSetPermissions_602666(
    name: "updateDataSetPermissions", meth: HttpMethod.HttpPost,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}/permissions",
    validator: validate_UpdateDataSetPermissions_602667, base: "/",
    url: url_UpdateDataSetPermissions_602668, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDataSetPermissions_602651 = ref object of OpenApiRestCall_601389
proc url_DescribeDataSetPermissions_602653(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeDataSetPermissions_602652(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_602654 = path.getOrDefault("AwsAccountId")
  valid_602654 = validateParameter(valid_602654, JString, required = true,
                                 default = nil)
  if valid_602654 != nil:
    section.add "AwsAccountId", valid_602654
  var valid_602655 = path.getOrDefault("DataSetId")
  valid_602655 = validateParameter(valid_602655, JString, required = true,
                                 default = nil)
  if valid_602655 != nil:
    section.add "DataSetId", valid_602655
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602656 = header.getOrDefault("X-Amz-Signature")
  valid_602656 = validateParameter(valid_602656, JString, required = false,
                                 default = nil)
  if valid_602656 != nil:
    section.add "X-Amz-Signature", valid_602656
  var valid_602657 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602657 = validateParameter(valid_602657, JString, required = false,
                                 default = nil)
  if valid_602657 != nil:
    section.add "X-Amz-Content-Sha256", valid_602657
  var valid_602658 = header.getOrDefault("X-Amz-Date")
  valid_602658 = validateParameter(valid_602658, JString, required = false,
                                 default = nil)
  if valid_602658 != nil:
    section.add "X-Amz-Date", valid_602658
  var valid_602659 = header.getOrDefault("X-Amz-Credential")
  valid_602659 = validateParameter(valid_602659, JString, required = false,
                                 default = nil)
  if valid_602659 != nil:
    section.add "X-Amz-Credential", valid_602659
  var valid_602660 = header.getOrDefault("X-Amz-Security-Token")
  valid_602660 = validateParameter(valid_602660, JString, required = false,
                                 default = nil)
  if valid_602660 != nil:
    section.add "X-Amz-Security-Token", valid_602660
  var valid_602661 = header.getOrDefault("X-Amz-Algorithm")
  valid_602661 = validateParameter(valid_602661, JString, required = false,
                                 default = nil)
  if valid_602661 != nil:
    section.add "X-Amz-Algorithm", valid_602661
  var valid_602662 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602662 = validateParameter(valid_602662, JString, required = false,
                                 default = nil)
  if valid_602662 != nil:
    section.add "X-Amz-SignedHeaders", valid_602662
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602663: Call_DescribeDataSetPermissions_602651; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the permissions on a dataset.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:dataset/data-set-id</code>.</p>
  ## 
  let valid = call_602663.validator(path, query, header, formData, body)
  let scheme = call_602663.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602663.url(scheme.get, call_602663.host, call_602663.base,
                         call_602663.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602663, url, valid)

proc call*(call_602664: Call_DescribeDataSetPermissions_602651;
          AwsAccountId: string; DataSetId: string): Recallable =
  ## describeDataSetPermissions
  ## <p>Describes the permissions on a dataset.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:dataset/data-set-id</code>.</p>
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSetId: string (required)
  ##            : The ID for the dataset that you want to create. This ID is unique per AWS Region for each AWS account.
  var path_602665 = newJObject()
  add(path_602665, "AwsAccountId", newJString(AwsAccountId))
  add(path_602665, "DataSetId", newJString(DataSetId))
  result = call_602664.call(path_602665, nil, nil, nil, nil)

var describeDataSetPermissions* = Call_DescribeDataSetPermissions_602651(
    name: "describeDataSetPermissions", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}/permissions",
    validator: validate_DescribeDataSetPermissions_602652, base: "/",
    url: url_DescribeDataSetPermissions_602653,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDataSourcePermissions_602698 = ref object of OpenApiRestCall_601389
proc url_UpdateDataSourcePermissions_602700(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDataSourcePermissions_602699(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the permissions to a data source.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DataSourceId: JString (required)
  ##               : The ID of the data source. This ID is unique per AWS Region for each AWS account. 
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `DataSourceId` field"
  var valid_602701 = path.getOrDefault("DataSourceId")
  valid_602701 = validateParameter(valid_602701, JString, required = true,
                                 default = nil)
  if valid_602701 != nil:
    section.add "DataSourceId", valid_602701
  var valid_602702 = path.getOrDefault("AwsAccountId")
  valid_602702 = validateParameter(valid_602702, JString, required = true,
                                 default = nil)
  if valid_602702 != nil:
    section.add "AwsAccountId", valid_602702
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602703 = header.getOrDefault("X-Amz-Signature")
  valid_602703 = validateParameter(valid_602703, JString, required = false,
                                 default = nil)
  if valid_602703 != nil:
    section.add "X-Amz-Signature", valid_602703
  var valid_602704 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602704 = validateParameter(valid_602704, JString, required = false,
                                 default = nil)
  if valid_602704 != nil:
    section.add "X-Amz-Content-Sha256", valid_602704
  var valid_602705 = header.getOrDefault("X-Amz-Date")
  valid_602705 = validateParameter(valid_602705, JString, required = false,
                                 default = nil)
  if valid_602705 != nil:
    section.add "X-Amz-Date", valid_602705
  var valid_602706 = header.getOrDefault("X-Amz-Credential")
  valid_602706 = validateParameter(valid_602706, JString, required = false,
                                 default = nil)
  if valid_602706 != nil:
    section.add "X-Amz-Credential", valid_602706
  var valid_602707 = header.getOrDefault("X-Amz-Security-Token")
  valid_602707 = validateParameter(valid_602707, JString, required = false,
                                 default = nil)
  if valid_602707 != nil:
    section.add "X-Amz-Security-Token", valid_602707
  var valid_602708 = header.getOrDefault("X-Amz-Algorithm")
  valid_602708 = validateParameter(valid_602708, JString, required = false,
                                 default = nil)
  if valid_602708 != nil:
    section.add "X-Amz-Algorithm", valid_602708
  var valid_602709 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602709 = validateParameter(valid_602709, JString, required = false,
                                 default = nil)
  if valid_602709 != nil:
    section.add "X-Amz-SignedHeaders", valid_602709
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602711: Call_UpdateDataSourcePermissions_602698; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the permissions to a data source.
  ## 
  let valid = call_602711.validator(path, query, header, formData, body)
  let scheme = call_602711.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602711.url(scheme.get, call_602711.host, call_602711.base,
                         call_602711.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602711, url, valid)

proc call*(call_602712: Call_UpdateDataSourcePermissions_602698;
          DataSourceId: string; AwsAccountId: string; body: JsonNode): Recallable =
  ## updateDataSourcePermissions
  ## Updates the permissions to a data source.
  ##   DataSourceId: string (required)
  ##               : The ID of the data source. This ID is unique per AWS Region for each AWS account. 
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   body: JObject (required)
  var path_602713 = newJObject()
  var body_602714 = newJObject()
  add(path_602713, "DataSourceId", newJString(DataSourceId))
  add(path_602713, "AwsAccountId", newJString(AwsAccountId))
  if body != nil:
    body_602714 = body
  result = call_602712.call(path_602713, nil, nil, nil, body_602714)

var updateDataSourcePermissions* = Call_UpdateDataSourcePermissions_602698(
    name: "updateDataSourcePermissions", meth: HttpMethod.HttpPost,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sources/{DataSourceId}/permissions",
    validator: validate_UpdateDataSourcePermissions_602699, base: "/",
    url: url_UpdateDataSourcePermissions_602700,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDataSourcePermissions_602683 = ref object of OpenApiRestCall_601389
proc url_DescribeDataSourcePermissions_602685(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeDataSourcePermissions_602684(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the resource permissions for a data source.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DataSourceId: JString (required)
  ##               : The ID of the data source. This ID is unique per AWS Region for each AWS account.
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `DataSourceId` field"
  var valid_602686 = path.getOrDefault("DataSourceId")
  valid_602686 = validateParameter(valid_602686, JString, required = true,
                                 default = nil)
  if valid_602686 != nil:
    section.add "DataSourceId", valid_602686
  var valid_602687 = path.getOrDefault("AwsAccountId")
  valid_602687 = validateParameter(valid_602687, JString, required = true,
                                 default = nil)
  if valid_602687 != nil:
    section.add "AwsAccountId", valid_602687
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602688 = header.getOrDefault("X-Amz-Signature")
  valid_602688 = validateParameter(valid_602688, JString, required = false,
                                 default = nil)
  if valid_602688 != nil:
    section.add "X-Amz-Signature", valid_602688
  var valid_602689 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602689 = validateParameter(valid_602689, JString, required = false,
                                 default = nil)
  if valid_602689 != nil:
    section.add "X-Amz-Content-Sha256", valid_602689
  var valid_602690 = header.getOrDefault("X-Amz-Date")
  valid_602690 = validateParameter(valid_602690, JString, required = false,
                                 default = nil)
  if valid_602690 != nil:
    section.add "X-Amz-Date", valid_602690
  var valid_602691 = header.getOrDefault("X-Amz-Credential")
  valid_602691 = validateParameter(valid_602691, JString, required = false,
                                 default = nil)
  if valid_602691 != nil:
    section.add "X-Amz-Credential", valid_602691
  var valid_602692 = header.getOrDefault("X-Amz-Security-Token")
  valid_602692 = validateParameter(valid_602692, JString, required = false,
                                 default = nil)
  if valid_602692 != nil:
    section.add "X-Amz-Security-Token", valid_602692
  var valid_602693 = header.getOrDefault("X-Amz-Algorithm")
  valid_602693 = validateParameter(valid_602693, JString, required = false,
                                 default = nil)
  if valid_602693 != nil:
    section.add "X-Amz-Algorithm", valid_602693
  var valid_602694 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602694 = validateParameter(valid_602694, JString, required = false,
                                 default = nil)
  if valid_602694 != nil:
    section.add "X-Amz-SignedHeaders", valid_602694
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602695: Call_DescribeDataSourcePermissions_602683; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the resource permissions for a data source.
  ## 
  let valid = call_602695.validator(path, query, header, formData, body)
  let scheme = call_602695.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602695.url(scheme.get, call_602695.host, call_602695.base,
                         call_602695.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602695, url, valid)

proc call*(call_602696: Call_DescribeDataSourcePermissions_602683;
          DataSourceId: string; AwsAccountId: string): Recallable =
  ## describeDataSourcePermissions
  ## Describes the resource permissions for a data source.
  ##   DataSourceId: string (required)
  ##               : The ID of the data source. This ID is unique per AWS Region for each AWS account.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  var path_602697 = newJObject()
  add(path_602697, "DataSourceId", newJString(DataSourceId))
  add(path_602697, "AwsAccountId", newJString(AwsAccountId))
  result = call_602696.call(path_602697, nil, nil, nil, nil)

var describeDataSourcePermissions* = Call_DescribeDataSourcePermissions_602683(
    name: "describeDataSourcePermissions", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sources/{DataSourceId}/permissions",
    validator: validate_DescribeDataSourcePermissions_602684, base: "/",
    url: url_DescribeDataSourcePermissions_602685,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIAMPolicyAssignment_602731 = ref object of OpenApiRestCall_601389
proc url_UpdateIAMPolicyAssignment_602733(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateIAMPolicyAssignment_602732(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an existing IAM policy assignment. This operation updates only the optional parameter or parameters that are specified in the request.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account that contains the IAM policy assignment.
  ##   Namespace: JString (required)
  ##            : The namespace of the assignment.
  ##   AssignmentName: JString (required)
  ##                 : The name of the assignment. This name must be unique within an AWS account.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_602734 = path.getOrDefault("AwsAccountId")
  valid_602734 = validateParameter(valid_602734, JString, required = true,
                                 default = nil)
  if valid_602734 != nil:
    section.add "AwsAccountId", valid_602734
  var valid_602735 = path.getOrDefault("Namespace")
  valid_602735 = validateParameter(valid_602735, JString, required = true,
                                 default = nil)
  if valid_602735 != nil:
    section.add "Namespace", valid_602735
  var valid_602736 = path.getOrDefault("AssignmentName")
  valid_602736 = validateParameter(valid_602736, JString, required = true,
                                 default = nil)
  if valid_602736 != nil:
    section.add "AssignmentName", valid_602736
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602737 = header.getOrDefault("X-Amz-Signature")
  valid_602737 = validateParameter(valid_602737, JString, required = false,
                                 default = nil)
  if valid_602737 != nil:
    section.add "X-Amz-Signature", valid_602737
  var valid_602738 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602738 = validateParameter(valid_602738, JString, required = false,
                                 default = nil)
  if valid_602738 != nil:
    section.add "X-Amz-Content-Sha256", valid_602738
  var valid_602739 = header.getOrDefault("X-Amz-Date")
  valid_602739 = validateParameter(valid_602739, JString, required = false,
                                 default = nil)
  if valid_602739 != nil:
    section.add "X-Amz-Date", valid_602739
  var valid_602740 = header.getOrDefault("X-Amz-Credential")
  valid_602740 = validateParameter(valid_602740, JString, required = false,
                                 default = nil)
  if valid_602740 != nil:
    section.add "X-Amz-Credential", valid_602740
  var valid_602741 = header.getOrDefault("X-Amz-Security-Token")
  valid_602741 = validateParameter(valid_602741, JString, required = false,
                                 default = nil)
  if valid_602741 != nil:
    section.add "X-Amz-Security-Token", valid_602741
  var valid_602742 = header.getOrDefault("X-Amz-Algorithm")
  valid_602742 = validateParameter(valid_602742, JString, required = false,
                                 default = nil)
  if valid_602742 != nil:
    section.add "X-Amz-Algorithm", valid_602742
  var valid_602743 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602743 = validateParameter(valid_602743, JString, required = false,
                                 default = nil)
  if valid_602743 != nil:
    section.add "X-Amz-SignedHeaders", valid_602743
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602745: Call_UpdateIAMPolicyAssignment_602731; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing IAM policy assignment. This operation updates only the optional parameter or parameters that are specified in the request.
  ## 
  let valid = call_602745.validator(path, query, header, formData, body)
  let scheme = call_602745.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602745.url(scheme.get, call_602745.host, call_602745.base,
                         call_602745.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602745, url, valid)

proc call*(call_602746: Call_UpdateIAMPolicyAssignment_602731;
          AwsAccountId: string; Namespace: string; AssignmentName: string;
          body: JsonNode): Recallable =
  ## updateIAMPolicyAssignment
  ## Updates an existing IAM policy assignment. This operation updates only the optional parameter or parameters that are specified in the request.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the IAM policy assignment.
  ##   Namespace: string (required)
  ##            : The namespace of the assignment.
  ##   AssignmentName: string (required)
  ##                 : The name of the assignment. This name must be unique within an AWS account.
  ##   body: JObject (required)
  var path_602747 = newJObject()
  var body_602748 = newJObject()
  add(path_602747, "AwsAccountId", newJString(AwsAccountId))
  add(path_602747, "Namespace", newJString(Namespace))
  add(path_602747, "AssignmentName", newJString(AssignmentName))
  if body != nil:
    body_602748 = body
  result = call_602746.call(path_602747, nil, nil, nil, body_602748)

var updateIAMPolicyAssignment* = Call_UpdateIAMPolicyAssignment_602731(
    name: "updateIAMPolicyAssignment", meth: HttpMethod.HttpPut,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/iam-policy-assignments/{AssignmentName}",
    validator: validate_UpdateIAMPolicyAssignment_602732, base: "/",
    url: url_UpdateIAMPolicyAssignment_602733,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeIAMPolicyAssignment_602715 = ref object of OpenApiRestCall_601389
proc url_DescribeIAMPolicyAssignment_602717(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeIAMPolicyAssignment_602716(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes an existing IAM policy assignment, as specified by the assignment name.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account that contains the assignment that you want to describe.
  ##   Namespace: JString (required)
  ##            : The namespace that contains the assignment.
  ##   AssignmentName: JString (required)
  ##                 : The name of the assignment. 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_602718 = path.getOrDefault("AwsAccountId")
  valid_602718 = validateParameter(valid_602718, JString, required = true,
                                 default = nil)
  if valid_602718 != nil:
    section.add "AwsAccountId", valid_602718
  var valid_602719 = path.getOrDefault("Namespace")
  valid_602719 = validateParameter(valid_602719, JString, required = true,
                                 default = nil)
  if valid_602719 != nil:
    section.add "Namespace", valid_602719
  var valid_602720 = path.getOrDefault("AssignmentName")
  valid_602720 = validateParameter(valid_602720, JString, required = true,
                                 default = nil)
  if valid_602720 != nil:
    section.add "AssignmentName", valid_602720
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602721 = header.getOrDefault("X-Amz-Signature")
  valid_602721 = validateParameter(valid_602721, JString, required = false,
                                 default = nil)
  if valid_602721 != nil:
    section.add "X-Amz-Signature", valid_602721
  var valid_602722 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602722 = validateParameter(valid_602722, JString, required = false,
                                 default = nil)
  if valid_602722 != nil:
    section.add "X-Amz-Content-Sha256", valid_602722
  var valid_602723 = header.getOrDefault("X-Amz-Date")
  valid_602723 = validateParameter(valid_602723, JString, required = false,
                                 default = nil)
  if valid_602723 != nil:
    section.add "X-Amz-Date", valid_602723
  var valid_602724 = header.getOrDefault("X-Amz-Credential")
  valid_602724 = validateParameter(valid_602724, JString, required = false,
                                 default = nil)
  if valid_602724 != nil:
    section.add "X-Amz-Credential", valid_602724
  var valid_602725 = header.getOrDefault("X-Amz-Security-Token")
  valid_602725 = validateParameter(valid_602725, JString, required = false,
                                 default = nil)
  if valid_602725 != nil:
    section.add "X-Amz-Security-Token", valid_602725
  var valid_602726 = header.getOrDefault("X-Amz-Algorithm")
  valid_602726 = validateParameter(valid_602726, JString, required = false,
                                 default = nil)
  if valid_602726 != nil:
    section.add "X-Amz-Algorithm", valid_602726
  var valid_602727 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602727 = validateParameter(valid_602727, JString, required = false,
                                 default = nil)
  if valid_602727 != nil:
    section.add "X-Amz-SignedHeaders", valid_602727
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602728: Call_DescribeIAMPolicyAssignment_602715; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing IAM policy assignment, as specified by the assignment name.
  ## 
  let valid = call_602728.validator(path, query, header, formData, body)
  let scheme = call_602728.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602728.url(scheme.get, call_602728.host, call_602728.base,
                         call_602728.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602728, url, valid)

proc call*(call_602729: Call_DescribeIAMPolicyAssignment_602715;
          AwsAccountId: string; Namespace: string; AssignmentName: string): Recallable =
  ## describeIAMPolicyAssignment
  ## Describes an existing IAM policy assignment, as specified by the assignment name.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the assignment that you want to describe.
  ##   Namespace: string (required)
  ##            : The namespace that contains the assignment.
  ##   AssignmentName: string (required)
  ##                 : The name of the assignment. 
  var path_602730 = newJObject()
  add(path_602730, "AwsAccountId", newJString(AwsAccountId))
  add(path_602730, "Namespace", newJString(Namespace))
  add(path_602730, "AssignmentName", newJString(AssignmentName))
  result = call_602729.call(path_602730, nil, nil, nil, nil)

var describeIAMPolicyAssignment* = Call_DescribeIAMPolicyAssignment_602715(
    name: "describeIAMPolicyAssignment", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/iam-policy-assignments/{AssignmentName}",
    validator: validate_DescribeIAMPolicyAssignment_602716, base: "/",
    url: url_DescribeIAMPolicyAssignment_602717,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTemplatePermissions_602764 = ref object of OpenApiRestCall_601389
proc url_UpdateTemplatePermissions_602766(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateTemplatePermissions_602765(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_602767 = path.getOrDefault("AwsAccountId")
  valid_602767 = validateParameter(valid_602767, JString, required = true,
                                 default = nil)
  if valid_602767 != nil:
    section.add "AwsAccountId", valid_602767
  var valid_602768 = path.getOrDefault("TemplateId")
  valid_602768 = validateParameter(valid_602768, JString, required = true,
                                 default = nil)
  if valid_602768 != nil:
    section.add "TemplateId", valid_602768
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602769 = header.getOrDefault("X-Amz-Signature")
  valid_602769 = validateParameter(valid_602769, JString, required = false,
                                 default = nil)
  if valid_602769 != nil:
    section.add "X-Amz-Signature", valid_602769
  var valid_602770 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602770 = validateParameter(valid_602770, JString, required = false,
                                 default = nil)
  if valid_602770 != nil:
    section.add "X-Amz-Content-Sha256", valid_602770
  var valid_602771 = header.getOrDefault("X-Amz-Date")
  valid_602771 = validateParameter(valid_602771, JString, required = false,
                                 default = nil)
  if valid_602771 != nil:
    section.add "X-Amz-Date", valid_602771
  var valid_602772 = header.getOrDefault("X-Amz-Credential")
  valid_602772 = validateParameter(valid_602772, JString, required = false,
                                 default = nil)
  if valid_602772 != nil:
    section.add "X-Amz-Credential", valid_602772
  var valid_602773 = header.getOrDefault("X-Amz-Security-Token")
  valid_602773 = validateParameter(valid_602773, JString, required = false,
                                 default = nil)
  if valid_602773 != nil:
    section.add "X-Amz-Security-Token", valid_602773
  var valid_602774 = header.getOrDefault("X-Amz-Algorithm")
  valid_602774 = validateParameter(valid_602774, JString, required = false,
                                 default = nil)
  if valid_602774 != nil:
    section.add "X-Amz-Algorithm", valid_602774
  var valid_602775 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602775 = validateParameter(valid_602775, JString, required = false,
                                 default = nil)
  if valid_602775 != nil:
    section.add "X-Amz-SignedHeaders", valid_602775
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602777: Call_UpdateTemplatePermissions_602764; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the resource permissions for a template.
  ## 
  let valid = call_602777.validator(path, query, header, formData, body)
  let scheme = call_602777.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602777.url(scheme.get, call_602777.host, call_602777.base,
                         call_602777.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602777, url, valid)

proc call*(call_602778: Call_UpdateTemplatePermissions_602764;
          AwsAccountId: string; TemplateId: string; body: JsonNode): Recallable =
  ## updateTemplatePermissions
  ## Updates the resource permissions for a template.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the template.
  ##   TemplateId: string (required)
  ##             : The ID for the template.
  ##   body: JObject (required)
  var path_602779 = newJObject()
  var body_602780 = newJObject()
  add(path_602779, "AwsAccountId", newJString(AwsAccountId))
  add(path_602779, "TemplateId", newJString(TemplateId))
  if body != nil:
    body_602780 = body
  result = call_602778.call(path_602779, nil, nil, nil, body_602780)

var updateTemplatePermissions* = Call_UpdateTemplatePermissions_602764(
    name: "updateTemplatePermissions", meth: HttpMethod.HttpPut,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates/{TemplateId}/permissions",
    validator: validate_UpdateTemplatePermissions_602765, base: "/",
    url: url_UpdateTemplatePermissions_602766,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTemplatePermissions_602749 = ref object of OpenApiRestCall_601389
proc url_DescribeTemplatePermissions_602751(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeTemplatePermissions_602750(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_602752 = path.getOrDefault("AwsAccountId")
  valid_602752 = validateParameter(valid_602752, JString, required = true,
                                 default = nil)
  if valid_602752 != nil:
    section.add "AwsAccountId", valid_602752
  var valid_602753 = path.getOrDefault("TemplateId")
  valid_602753 = validateParameter(valid_602753, JString, required = true,
                                 default = nil)
  if valid_602753 != nil:
    section.add "TemplateId", valid_602753
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602754 = header.getOrDefault("X-Amz-Signature")
  valid_602754 = validateParameter(valid_602754, JString, required = false,
                                 default = nil)
  if valid_602754 != nil:
    section.add "X-Amz-Signature", valid_602754
  var valid_602755 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602755 = validateParameter(valid_602755, JString, required = false,
                                 default = nil)
  if valid_602755 != nil:
    section.add "X-Amz-Content-Sha256", valid_602755
  var valid_602756 = header.getOrDefault("X-Amz-Date")
  valid_602756 = validateParameter(valid_602756, JString, required = false,
                                 default = nil)
  if valid_602756 != nil:
    section.add "X-Amz-Date", valid_602756
  var valid_602757 = header.getOrDefault("X-Amz-Credential")
  valid_602757 = validateParameter(valid_602757, JString, required = false,
                                 default = nil)
  if valid_602757 != nil:
    section.add "X-Amz-Credential", valid_602757
  var valid_602758 = header.getOrDefault("X-Amz-Security-Token")
  valid_602758 = validateParameter(valid_602758, JString, required = false,
                                 default = nil)
  if valid_602758 != nil:
    section.add "X-Amz-Security-Token", valid_602758
  var valid_602759 = header.getOrDefault("X-Amz-Algorithm")
  valid_602759 = validateParameter(valid_602759, JString, required = false,
                                 default = nil)
  if valid_602759 != nil:
    section.add "X-Amz-Algorithm", valid_602759
  var valid_602760 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602760 = validateParameter(valid_602760, JString, required = false,
                                 default = nil)
  if valid_602760 != nil:
    section.add "X-Amz-SignedHeaders", valid_602760
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602761: Call_DescribeTemplatePermissions_602749; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes read and write permissions on a template.
  ## 
  let valid = call_602761.validator(path, query, header, formData, body)
  let scheme = call_602761.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602761.url(scheme.get, call_602761.host, call_602761.base,
                         call_602761.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602761, url, valid)

proc call*(call_602762: Call_DescribeTemplatePermissions_602749;
          AwsAccountId: string; TemplateId: string): Recallable =
  ## describeTemplatePermissions
  ## Describes read and write permissions on a template.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the template that you're describing.
  ##   TemplateId: string (required)
  ##             : The ID for the template.
  var path_602763 = newJObject()
  add(path_602763, "AwsAccountId", newJString(AwsAccountId))
  add(path_602763, "TemplateId", newJString(TemplateId))
  result = call_602762.call(path_602763, nil, nil, nil, nil)

var describeTemplatePermissions* = Call_DescribeTemplatePermissions_602749(
    name: "describeTemplatePermissions", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates/{TemplateId}/permissions",
    validator: validate_DescribeTemplatePermissions_602750, base: "/",
    url: url_DescribeTemplatePermissions_602751,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDashboardEmbedUrl_602781 = ref object of OpenApiRestCall_601389
proc url_GetDashboardEmbedUrl_602783(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDashboardEmbedUrl_602782(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_602784 = path.getOrDefault("AwsAccountId")
  valid_602784 = validateParameter(valid_602784, JString, required = true,
                                 default = nil)
  if valid_602784 != nil:
    section.add "AwsAccountId", valid_602784
  var valid_602785 = path.getOrDefault("DashboardId")
  valid_602785 = validateParameter(valid_602785, JString, required = true,
                                 default = nil)
  if valid_602785 != nil:
    section.add "DashboardId", valid_602785
  result.add "path", section
  ## parameters in `query` object:
  ##   reset-disabled: JBool
  ##                 : Remove the reset button on the embedded dashboard. The default is FALSE, which enables the reset button.
  ##   creds-type: JString (required)
  ##             : The authentication method that the user uses to sign in.
  ##   user-arn: JString
  ##           : <p>The Amazon QuickSight user's Amazon Resource Name (ARN), for use with <code>QUICKSIGHT</code> identity type. You can use this for any Amazon QuickSight users in your account (readers, authors, or admins) authenticated as one of the following:</p> <ul> <li> <p>Active Directory (AD) users or group members</p> </li> <li> <p>Invited nonfederated users</p> </li> <li> <p>IAM users and IAM role-based sessions authenticated through Federated Single Sign-On using SAML, OpenID Connect, or IAM federation.</p> </li> </ul>
  ##   session-lifetime: JInt
  ##                   : How many minutes the session is valid. The session lifetime must be 15-600 minutes.
  ##   undo-redo-disabled: JBool
  ##                     : Remove the undo/redo button on the embedded dashboard. The default is FALSE, which enables the undo/redo button.
  section = newJObject()
  var valid_602786 = query.getOrDefault("reset-disabled")
  valid_602786 = validateParameter(valid_602786, JBool, required = false, default = nil)
  if valid_602786 != nil:
    section.add "reset-disabled", valid_602786
  assert query != nil,
        "query argument is necessary due to required `creds-type` field"
  var valid_602800 = query.getOrDefault("creds-type")
  valid_602800 = validateParameter(valid_602800, JString, required = true,
                                 default = newJString("IAM"))
  if valid_602800 != nil:
    section.add "creds-type", valid_602800
  var valid_602801 = query.getOrDefault("user-arn")
  valid_602801 = validateParameter(valid_602801, JString, required = false,
                                 default = nil)
  if valid_602801 != nil:
    section.add "user-arn", valid_602801
  var valid_602802 = query.getOrDefault("session-lifetime")
  valid_602802 = validateParameter(valid_602802, JInt, required = false, default = nil)
  if valid_602802 != nil:
    section.add "session-lifetime", valid_602802
  var valid_602803 = query.getOrDefault("undo-redo-disabled")
  valid_602803 = validateParameter(valid_602803, JBool, required = false, default = nil)
  if valid_602803 != nil:
    section.add "undo-redo-disabled", valid_602803
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602804 = header.getOrDefault("X-Amz-Signature")
  valid_602804 = validateParameter(valid_602804, JString, required = false,
                                 default = nil)
  if valid_602804 != nil:
    section.add "X-Amz-Signature", valid_602804
  var valid_602805 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602805 = validateParameter(valid_602805, JString, required = false,
                                 default = nil)
  if valid_602805 != nil:
    section.add "X-Amz-Content-Sha256", valid_602805
  var valid_602806 = header.getOrDefault("X-Amz-Date")
  valid_602806 = validateParameter(valid_602806, JString, required = false,
                                 default = nil)
  if valid_602806 != nil:
    section.add "X-Amz-Date", valid_602806
  var valid_602807 = header.getOrDefault("X-Amz-Credential")
  valid_602807 = validateParameter(valid_602807, JString, required = false,
                                 default = nil)
  if valid_602807 != nil:
    section.add "X-Amz-Credential", valid_602807
  var valid_602808 = header.getOrDefault("X-Amz-Security-Token")
  valid_602808 = validateParameter(valid_602808, JString, required = false,
                                 default = nil)
  if valid_602808 != nil:
    section.add "X-Amz-Security-Token", valid_602808
  var valid_602809 = header.getOrDefault("X-Amz-Algorithm")
  valid_602809 = validateParameter(valid_602809, JString, required = false,
                                 default = nil)
  if valid_602809 != nil:
    section.add "X-Amz-Algorithm", valid_602809
  var valid_602810 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602810 = validateParameter(valid_602810, JString, required = false,
                                 default = nil)
  if valid_602810 != nil:
    section.add "X-Amz-SignedHeaders", valid_602810
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602811: Call_GetDashboardEmbedUrl_602781; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Generates a server-side embeddable URL and authorization code. For this process to work properly, first configure the dashboards and user permissions. For more information, see <a href="https://docs.aws.amazon.com/quicksight/latest/user/embedding-dashboards.html">Embedding Amazon QuickSight Dashboards</a> in the <i>Amazon QuickSight User Guide</i> or <a href="https://docs.aws.amazon.com/quicksight/latest/APIReference/qs-dev-embedded-dashboards.html">Embedding Amazon QuickSight Dashboards</a> in the <i>Amazon QuickSight API Reference</i>.</p> <p>Currently, you can use <code>GetDashboardEmbedURL</code> only from the server, not from the user’s browser.</p>
  ## 
  let valid = call_602811.validator(path, query, header, formData, body)
  let scheme = call_602811.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602811.url(scheme.get, call_602811.host, call_602811.base,
                         call_602811.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602811, url, valid)

proc call*(call_602812: Call_GetDashboardEmbedUrl_602781; AwsAccountId: string;
          DashboardId: string; resetDisabled: bool = false; credsType: string = "IAM";
          userArn: string = ""; sessionLifetime: int = 0; undoRedoDisabled: bool = false): Recallable =
  ## getDashboardEmbedUrl
  ## <p>Generates a server-side embeddable URL and authorization code. For this process to work properly, first configure the dashboards and user permissions. For more information, see <a href="https://docs.aws.amazon.com/quicksight/latest/user/embedding-dashboards.html">Embedding Amazon QuickSight Dashboards</a> in the <i>Amazon QuickSight User Guide</i> or <a href="https://docs.aws.amazon.com/quicksight/latest/APIReference/qs-dev-embedded-dashboards.html">Embedding Amazon QuickSight Dashboards</a> in the <i>Amazon QuickSight API Reference</i>.</p> <p>Currently, you can use <code>GetDashboardEmbedURL</code> only from the server, not from the user’s browser.</p>
  ##   resetDisabled: bool
  ##                : Remove the reset button on the embedded dashboard. The default is FALSE, which enables the reset button.
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that contains the dashboard that you're embedding.
  ##   credsType: string (required)
  ##            : The authentication method that the user uses to sign in.
  ##   userArn: string
  ##          : <p>The Amazon QuickSight user's Amazon Resource Name (ARN), for use with <code>QUICKSIGHT</code> identity type. You can use this for any Amazon QuickSight users in your account (readers, authors, or admins) authenticated as one of the following:</p> <ul> <li> <p>Active Directory (AD) users or group members</p> </li> <li> <p>Invited nonfederated users</p> </li> <li> <p>IAM users and IAM role-based sessions authenticated through Federated Single Sign-On using SAML, OpenID Connect, or IAM federation.</p> </li> </ul>
  ##   DashboardId: string (required)
  ##              : The ID for the dashboard, also added to the IAM policy.
  ##   sessionLifetime: int
  ##                  : How many minutes the session is valid. The session lifetime must be 15-600 minutes.
  ##   undoRedoDisabled: bool
  ##                   : Remove the undo/redo button on the embedded dashboard. The default is FALSE, which enables the undo/redo button.
  var path_602813 = newJObject()
  var query_602814 = newJObject()
  add(query_602814, "reset-disabled", newJBool(resetDisabled))
  add(path_602813, "AwsAccountId", newJString(AwsAccountId))
  add(query_602814, "creds-type", newJString(credsType))
  add(query_602814, "user-arn", newJString(userArn))
  add(path_602813, "DashboardId", newJString(DashboardId))
  add(query_602814, "session-lifetime", newJInt(sessionLifetime))
  add(query_602814, "undo-redo-disabled", newJBool(undoRedoDisabled))
  result = call_602812.call(path_602813, query_602814, nil, nil, nil)

var getDashboardEmbedUrl* = Call_GetDashboardEmbedUrl_602781(
    name: "getDashboardEmbedUrl", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}/embed-url#creds-type",
    validator: validate_GetDashboardEmbedUrl_602782, base: "/",
    url: url_GetDashboardEmbedUrl_602783, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDashboardVersions_602815 = ref object of OpenApiRestCall_601389
proc url_ListDashboardVersions_602817(protocol: Scheme; host: string; base: string;
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
               (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListDashboardVersions_602816(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_602818 = path.getOrDefault("AwsAccountId")
  valid_602818 = validateParameter(valid_602818, JString, required = true,
                                 default = nil)
  if valid_602818 != nil:
    section.add "AwsAccountId", valid_602818
  var valid_602819 = path.getOrDefault("DashboardId")
  valid_602819 = validateParameter(valid_602819, JString, required = true,
                                 default = nil)
  if valid_602819 != nil:
    section.add "DashboardId", valid_602819
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   max-results: JInt
  ##              : The maximum number of results to be returned per request.
  ##   next-token: JString
  ##             : The token for the next set of results, or null if there are no more results.
  section = newJObject()
  var valid_602820 = query.getOrDefault("MaxResults")
  valid_602820 = validateParameter(valid_602820, JString, required = false,
                                 default = nil)
  if valid_602820 != nil:
    section.add "MaxResults", valid_602820
  var valid_602821 = query.getOrDefault("NextToken")
  valid_602821 = validateParameter(valid_602821, JString, required = false,
                                 default = nil)
  if valid_602821 != nil:
    section.add "NextToken", valid_602821
  var valid_602822 = query.getOrDefault("max-results")
  valid_602822 = validateParameter(valid_602822, JInt, required = false, default = nil)
  if valid_602822 != nil:
    section.add "max-results", valid_602822
  var valid_602823 = query.getOrDefault("next-token")
  valid_602823 = validateParameter(valid_602823, JString, required = false,
                                 default = nil)
  if valid_602823 != nil:
    section.add "next-token", valid_602823
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602824 = header.getOrDefault("X-Amz-Signature")
  valid_602824 = validateParameter(valid_602824, JString, required = false,
                                 default = nil)
  if valid_602824 != nil:
    section.add "X-Amz-Signature", valid_602824
  var valid_602825 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602825 = validateParameter(valid_602825, JString, required = false,
                                 default = nil)
  if valid_602825 != nil:
    section.add "X-Amz-Content-Sha256", valid_602825
  var valid_602826 = header.getOrDefault("X-Amz-Date")
  valid_602826 = validateParameter(valid_602826, JString, required = false,
                                 default = nil)
  if valid_602826 != nil:
    section.add "X-Amz-Date", valid_602826
  var valid_602827 = header.getOrDefault("X-Amz-Credential")
  valid_602827 = validateParameter(valid_602827, JString, required = false,
                                 default = nil)
  if valid_602827 != nil:
    section.add "X-Amz-Credential", valid_602827
  var valid_602828 = header.getOrDefault("X-Amz-Security-Token")
  valid_602828 = validateParameter(valid_602828, JString, required = false,
                                 default = nil)
  if valid_602828 != nil:
    section.add "X-Amz-Security-Token", valid_602828
  var valid_602829 = header.getOrDefault("X-Amz-Algorithm")
  valid_602829 = validateParameter(valid_602829, JString, required = false,
                                 default = nil)
  if valid_602829 != nil:
    section.add "X-Amz-Algorithm", valid_602829
  var valid_602830 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602830 = validateParameter(valid_602830, JString, required = false,
                                 default = nil)
  if valid_602830 != nil:
    section.add "X-Amz-SignedHeaders", valid_602830
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602831: Call_ListDashboardVersions_602815; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all the versions of the dashboards in the QuickSight subscription.
  ## 
  let valid = call_602831.validator(path, query, header, formData, body)
  let scheme = call_602831.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602831.url(scheme.get, call_602831.host, call_602831.base,
                         call_602831.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602831, url, valid)

proc call*(call_602832: Call_ListDashboardVersions_602815; AwsAccountId: string;
          DashboardId: string; MaxResults: string = ""; NextToken: string = "";
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listDashboardVersions
  ## Lists all the versions of the dashboards in the QuickSight subscription.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the dashboard that you're listing versions for.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results to be returned per request.
  ##   DashboardId: string (required)
  ##              : The ID for the dashboard.
  ##   nextToken: string
  ##            : The token for the next set of results, or null if there are no more results.
  var path_602833 = newJObject()
  var query_602834 = newJObject()
  add(path_602833, "AwsAccountId", newJString(AwsAccountId))
  add(query_602834, "MaxResults", newJString(MaxResults))
  add(query_602834, "NextToken", newJString(NextToken))
  add(query_602834, "max-results", newJInt(maxResults))
  add(path_602833, "DashboardId", newJString(DashboardId))
  add(query_602834, "next-token", newJString(nextToken))
  result = call_602832.call(path_602833, query_602834, nil, nil, nil)

var listDashboardVersions* = Call_ListDashboardVersions_602815(
    name: "listDashboardVersions", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}/versions",
    validator: validate_ListDashboardVersions_602816, base: "/",
    url: url_ListDashboardVersions_602817, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDashboards_602835 = ref object of OpenApiRestCall_601389
proc url_ListDashboards_602837(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListDashboards_602836(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
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
  var valid_602838 = path.getOrDefault("AwsAccountId")
  valid_602838 = validateParameter(valid_602838, JString, required = true,
                                 default = nil)
  if valid_602838 != nil:
    section.add "AwsAccountId", valid_602838
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   max-results: JInt
  ##              : The maximum number of results to be returned per request.
  ##   next-token: JString
  ##             : The token for the next set of results, or null if there are no more results.
  section = newJObject()
  var valid_602839 = query.getOrDefault("MaxResults")
  valid_602839 = validateParameter(valid_602839, JString, required = false,
                                 default = nil)
  if valid_602839 != nil:
    section.add "MaxResults", valid_602839
  var valid_602840 = query.getOrDefault("NextToken")
  valid_602840 = validateParameter(valid_602840, JString, required = false,
                                 default = nil)
  if valid_602840 != nil:
    section.add "NextToken", valid_602840
  var valid_602841 = query.getOrDefault("max-results")
  valid_602841 = validateParameter(valid_602841, JInt, required = false, default = nil)
  if valid_602841 != nil:
    section.add "max-results", valid_602841
  var valid_602842 = query.getOrDefault("next-token")
  valid_602842 = validateParameter(valid_602842, JString, required = false,
                                 default = nil)
  if valid_602842 != nil:
    section.add "next-token", valid_602842
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602843 = header.getOrDefault("X-Amz-Signature")
  valid_602843 = validateParameter(valid_602843, JString, required = false,
                                 default = nil)
  if valid_602843 != nil:
    section.add "X-Amz-Signature", valid_602843
  var valid_602844 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602844 = validateParameter(valid_602844, JString, required = false,
                                 default = nil)
  if valid_602844 != nil:
    section.add "X-Amz-Content-Sha256", valid_602844
  var valid_602845 = header.getOrDefault("X-Amz-Date")
  valid_602845 = validateParameter(valid_602845, JString, required = false,
                                 default = nil)
  if valid_602845 != nil:
    section.add "X-Amz-Date", valid_602845
  var valid_602846 = header.getOrDefault("X-Amz-Credential")
  valid_602846 = validateParameter(valid_602846, JString, required = false,
                                 default = nil)
  if valid_602846 != nil:
    section.add "X-Amz-Credential", valid_602846
  var valid_602847 = header.getOrDefault("X-Amz-Security-Token")
  valid_602847 = validateParameter(valid_602847, JString, required = false,
                                 default = nil)
  if valid_602847 != nil:
    section.add "X-Amz-Security-Token", valid_602847
  var valid_602848 = header.getOrDefault("X-Amz-Algorithm")
  valid_602848 = validateParameter(valid_602848, JString, required = false,
                                 default = nil)
  if valid_602848 != nil:
    section.add "X-Amz-Algorithm", valid_602848
  var valid_602849 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602849 = validateParameter(valid_602849, JString, required = false,
                                 default = nil)
  if valid_602849 != nil:
    section.add "X-Amz-SignedHeaders", valid_602849
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602850: Call_ListDashboards_602835; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists dashboards in an AWS account.
  ## 
  let valid = call_602850.validator(path, query, header, formData, body)
  let scheme = call_602850.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602850.url(scheme.get, call_602850.host, call_602850.base,
                         call_602850.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602850, url, valid)

proc call*(call_602851: Call_ListDashboards_602835; AwsAccountId: string;
          MaxResults: string = ""; NextToken: string = ""; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listDashboards
  ## Lists dashboards in an AWS account.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the dashboards that you're listing.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results to be returned per request.
  ##   nextToken: string
  ##            : The token for the next set of results, or null if there are no more results.
  var path_602852 = newJObject()
  var query_602853 = newJObject()
  add(path_602852, "AwsAccountId", newJString(AwsAccountId))
  add(query_602853, "MaxResults", newJString(MaxResults))
  add(query_602853, "NextToken", newJString(NextToken))
  add(query_602853, "max-results", newJInt(maxResults))
  add(query_602853, "next-token", newJString(nextToken))
  result = call_602851.call(path_602852, query_602853, nil, nil, nil)

var listDashboards* = Call_ListDashboards_602835(name: "listDashboards",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/dashboards",
    validator: validate_ListDashboards_602836, base: "/", url: url_ListDashboards_602837,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroupMemberships_602854 = ref object of OpenApiRestCall_601389
proc url_ListGroupMemberships_602856(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListGroupMemberships_602855(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_602857 = path.getOrDefault("GroupName")
  valid_602857 = validateParameter(valid_602857, JString, required = true,
                                 default = nil)
  if valid_602857 != nil:
    section.add "GroupName", valid_602857
  var valid_602858 = path.getOrDefault("AwsAccountId")
  valid_602858 = validateParameter(valid_602858, JString, required = true,
                                 default = nil)
  if valid_602858 != nil:
    section.add "AwsAccountId", valid_602858
  var valid_602859 = path.getOrDefault("Namespace")
  valid_602859 = validateParameter(valid_602859, JString, required = true,
                                 default = nil)
  if valid_602859 != nil:
    section.add "Namespace", valid_602859
  result.add "path", section
  ## parameters in `query` object:
  ##   max-results: JInt
  ##              : The maximum number of results to return from this request.
  ##   next-token: JString
  ##             : A pagination token that can be used in a subsequent request.
  section = newJObject()
  var valid_602860 = query.getOrDefault("max-results")
  valid_602860 = validateParameter(valid_602860, JInt, required = false, default = nil)
  if valid_602860 != nil:
    section.add "max-results", valid_602860
  var valid_602861 = query.getOrDefault("next-token")
  valid_602861 = validateParameter(valid_602861, JString, required = false,
                                 default = nil)
  if valid_602861 != nil:
    section.add "next-token", valid_602861
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602862 = header.getOrDefault("X-Amz-Signature")
  valid_602862 = validateParameter(valid_602862, JString, required = false,
                                 default = nil)
  if valid_602862 != nil:
    section.add "X-Amz-Signature", valid_602862
  var valid_602863 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602863 = validateParameter(valid_602863, JString, required = false,
                                 default = nil)
  if valid_602863 != nil:
    section.add "X-Amz-Content-Sha256", valid_602863
  var valid_602864 = header.getOrDefault("X-Amz-Date")
  valid_602864 = validateParameter(valid_602864, JString, required = false,
                                 default = nil)
  if valid_602864 != nil:
    section.add "X-Amz-Date", valid_602864
  var valid_602865 = header.getOrDefault("X-Amz-Credential")
  valid_602865 = validateParameter(valid_602865, JString, required = false,
                                 default = nil)
  if valid_602865 != nil:
    section.add "X-Amz-Credential", valid_602865
  var valid_602866 = header.getOrDefault("X-Amz-Security-Token")
  valid_602866 = validateParameter(valid_602866, JString, required = false,
                                 default = nil)
  if valid_602866 != nil:
    section.add "X-Amz-Security-Token", valid_602866
  var valid_602867 = header.getOrDefault("X-Amz-Algorithm")
  valid_602867 = validateParameter(valid_602867, JString, required = false,
                                 default = nil)
  if valid_602867 != nil:
    section.add "X-Amz-Algorithm", valid_602867
  var valid_602868 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602868 = validateParameter(valid_602868, JString, required = false,
                                 default = nil)
  if valid_602868 != nil:
    section.add "X-Amz-SignedHeaders", valid_602868
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602869: Call_ListGroupMemberships_602854; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists member users in a group.
  ## 
  let valid = call_602869.validator(path, query, header, formData, body)
  let scheme = call_602869.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602869.url(scheme.get, call_602869.host, call_602869.base,
                         call_602869.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602869, url, valid)

proc call*(call_602870: Call_ListGroupMemberships_602854; GroupName: string;
          AwsAccountId: string; Namespace: string; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listGroupMemberships
  ## Lists member users in a group.
  ##   GroupName: string (required)
  ##            : The name of the group that you want to see a membership list of.
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   maxResults: int
  ##             : The maximum number of results to return from this request.
  ##   nextToken: string
  ##            : A pagination token that can be used in a subsequent request.
  var path_602871 = newJObject()
  var query_602872 = newJObject()
  add(path_602871, "GroupName", newJString(GroupName))
  add(path_602871, "AwsAccountId", newJString(AwsAccountId))
  add(path_602871, "Namespace", newJString(Namespace))
  add(query_602872, "max-results", newJInt(maxResults))
  add(query_602872, "next-token", newJString(nextToken))
  result = call_602870.call(path_602871, query_602872, nil, nil, nil)

var listGroupMemberships* = Call_ListGroupMemberships_602854(
    name: "listGroupMemberships", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}/members",
    validator: validate_ListGroupMemberships_602855, base: "/",
    url: url_ListGroupMemberships_602856, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIAMPolicyAssignments_602873 = ref object of OpenApiRestCall_601389
proc url_ListIAMPolicyAssignments_602875(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListIAMPolicyAssignments_602874(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_602876 = path.getOrDefault("AwsAccountId")
  valid_602876 = validateParameter(valid_602876, JString, required = true,
                                 default = nil)
  if valid_602876 != nil:
    section.add "AwsAccountId", valid_602876
  var valid_602877 = path.getOrDefault("Namespace")
  valid_602877 = validateParameter(valid_602877, JString, required = true,
                                 default = nil)
  if valid_602877 != nil:
    section.add "Namespace", valid_602877
  result.add "path", section
  ## parameters in `query` object:
  ##   max-results: JInt
  ##              : The maximum number of results to be returned per request.
  ##   next-token: JString
  ##             : The token for the next set of results, or null if there are no more results.
  section = newJObject()
  var valid_602878 = query.getOrDefault("max-results")
  valid_602878 = validateParameter(valid_602878, JInt, required = false, default = nil)
  if valid_602878 != nil:
    section.add "max-results", valid_602878
  var valid_602879 = query.getOrDefault("next-token")
  valid_602879 = validateParameter(valid_602879, JString, required = false,
                                 default = nil)
  if valid_602879 != nil:
    section.add "next-token", valid_602879
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602880 = header.getOrDefault("X-Amz-Signature")
  valid_602880 = validateParameter(valid_602880, JString, required = false,
                                 default = nil)
  if valid_602880 != nil:
    section.add "X-Amz-Signature", valid_602880
  var valid_602881 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602881 = validateParameter(valid_602881, JString, required = false,
                                 default = nil)
  if valid_602881 != nil:
    section.add "X-Amz-Content-Sha256", valid_602881
  var valid_602882 = header.getOrDefault("X-Amz-Date")
  valid_602882 = validateParameter(valid_602882, JString, required = false,
                                 default = nil)
  if valid_602882 != nil:
    section.add "X-Amz-Date", valid_602882
  var valid_602883 = header.getOrDefault("X-Amz-Credential")
  valid_602883 = validateParameter(valid_602883, JString, required = false,
                                 default = nil)
  if valid_602883 != nil:
    section.add "X-Amz-Credential", valid_602883
  var valid_602884 = header.getOrDefault("X-Amz-Security-Token")
  valid_602884 = validateParameter(valid_602884, JString, required = false,
                                 default = nil)
  if valid_602884 != nil:
    section.add "X-Amz-Security-Token", valid_602884
  var valid_602885 = header.getOrDefault("X-Amz-Algorithm")
  valid_602885 = validateParameter(valid_602885, JString, required = false,
                                 default = nil)
  if valid_602885 != nil:
    section.add "X-Amz-Algorithm", valid_602885
  var valid_602886 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602886 = validateParameter(valid_602886, JString, required = false,
                                 default = nil)
  if valid_602886 != nil:
    section.add "X-Amz-SignedHeaders", valid_602886
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602888: Call_ListIAMPolicyAssignments_602873; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists IAM policy assignments in the current Amazon QuickSight account.
  ## 
  let valid = call_602888.validator(path, query, header, formData, body)
  let scheme = call_602888.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602888.url(scheme.get, call_602888.host, call_602888.base,
                         call_602888.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602888, url, valid)

proc call*(call_602889: Call_ListIAMPolicyAssignments_602873; AwsAccountId: string;
          Namespace: string; body: JsonNode; maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listIAMPolicyAssignments
  ## Lists IAM policy assignments in the current Amazon QuickSight account.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains these IAM policy assignments.
  ##   Namespace: string (required)
  ##            : The namespace for the assignments.
  ##   maxResults: int
  ##             : The maximum number of results to be returned per request.
  ##   body: JObject (required)
  ##   nextToken: string
  ##            : The token for the next set of results, or null if there are no more results.
  var path_602890 = newJObject()
  var query_602891 = newJObject()
  var body_602892 = newJObject()
  add(path_602890, "AwsAccountId", newJString(AwsAccountId))
  add(path_602890, "Namespace", newJString(Namespace))
  add(query_602891, "max-results", newJInt(maxResults))
  if body != nil:
    body_602892 = body
  add(query_602891, "next-token", newJString(nextToken))
  result = call_602889.call(path_602890, query_602891, nil, nil, body_602892)

var listIAMPolicyAssignments* = Call_ListIAMPolicyAssignments_602873(
    name: "listIAMPolicyAssignments", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/iam-policy-assignments",
    validator: validate_ListIAMPolicyAssignments_602874, base: "/",
    url: url_ListIAMPolicyAssignments_602875, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIAMPolicyAssignmentsForUser_602893 = ref object of OpenApiRestCall_601389
proc url_ListIAMPolicyAssignmentsForUser_602895(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListIAMPolicyAssignmentsForUser_602894(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists all the IAM policy assignments, including the Amazon Resource Names (ARNs) for the IAM policies assigned to the specified user and group or groups that the user belongs to.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account that contains the assignments.
  ##   Namespace: JString (required)
  ##            : The namespace of the assignment.
  ##   UserName: JString (required)
  ##           : The name of the user.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_602896 = path.getOrDefault("AwsAccountId")
  valid_602896 = validateParameter(valid_602896, JString, required = true,
                                 default = nil)
  if valid_602896 != nil:
    section.add "AwsAccountId", valid_602896
  var valid_602897 = path.getOrDefault("Namespace")
  valid_602897 = validateParameter(valid_602897, JString, required = true,
                                 default = nil)
  if valid_602897 != nil:
    section.add "Namespace", valid_602897
  var valid_602898 = path.getOrDefault("UserName")
  valid_602898 = validateParameter(valid_602898, JString, required = true,
                                 default = nil)
  if valid_602898 != nil:
    section.add "UserName", valid_602898
  result.add "path", section
  ## parameters in `query` object:
  ##   max-results: JInt
  ##              : The maximum number of results to be returned per request.
  ##   next-token: JString
  ##             : The token for the next set of results, or null if there are no more results.
  section = newJObject()
  var valid_602899 = query.getOrDefault("max-results")
  valid_602899 = validateParameter(valid_602899, JInt, required = false, default = nil)
  if valid_602899 != nil:
    section.add "max-results", valid_602899
  var valid_602900 = query.getOrDefault("next-token")
  valid_602900 = validateParameter(valid_602900, JString, required = false,
                                 default = nil)
  if valid_602900 != nil:
    section.add "next-token", valid_602900
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602901 = header.getOrDefault("X-Amz-Signature")
  valid_602901 = validateParameter(valid_602901, JString, required = false,
                                 default = nil)
  if valid_602901 != nil:
    section.add "X-Amz-Signature", valid_602901
  var valid_602902 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602902 = validateParameter(valid_602902, JString, required = false,
                                 default = nil)
  if valid_602902 != nil:
    section.add "X-Amz-Content-Sha256", valid_602902
  var valid_602903 = header.getOrDefault("X-Amz-Date")
  valid_602903 = validateParameter(valid_602903, JString, required = false,
                                 default = nil)
  if valid_602903 != nil:
    section.add "X-Amz-Date", valid_602903
  var valid_602904 = header.getOrDefault("X-Amz-Credential")
  valid_602904 = validateParameter(valid_602904, JString, required = false,
                                 default = nil)
  if valid_602904 != nil:
    section.add "X-Amz-Credential", valid_602904
  var valid_602905 = header.getOrDefault("X-Amz-Security-Token")
  valid_602905 = validateParameter(valid_602905, JString, required = false,
                                 default = nil)
  if valid_602905 != nil:
    section.add "X-Amz-Security-Token", valid_602905
  var valid_602906 = header.getOrDefault("X-Amz-Algorithm")
  valid_602906 = validateParameter(valid_602906, JString, required = false,
                                 default = nil)
  if valid_602906 != nil:
    section.add "X-Amz-Algorithm", valid_602906
  var valid_602907 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602907 = validateParameter(valid_602907, JString, required = false,
                                 default = nil)
  if valid_602907 != nil:
    section.add "X-Amz-SignedHeaders", valid_602907
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602908: Call_ListIAMPolicyAssignmentsForUser_602893;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists all the IAM policy assignments, including the Amazon Resource Names (ARNs) for the IAM policies assigned to the specified user and group or groups that the user belongs to.
  ## 
  let valid = call_602908.validator(path, query, header, formData, body)
  let scheme = call_602908.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602908.url(scheme.get, call_602908.host, call_602908.base,
                         call_602908.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602908, url, valid)

proc call*(call_602909: Call_ListIAMPolicyAssignmentsForUser_602893;
          AwsAccountId: string; Namespace: string; UserName: string;
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listIAMPolicyAssignmentsForUser
  ## Lists all the IAM policy assignments, including the Amazon Resource Names (ARNs) for the IAM policies assigned to the specified user and group or groups that the user belongs to.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the assignments.
  ##   Namespace: string (required)
  ##            : The namespace of the assignment.
  ##   UserName: string (required)
  ##           : The name of the user.
  ##   maxResults: int
  ##             : The maximum number of results to be returned per request.
  ##   nextToken: string
  ##            : The token for the next set of results, or null if there are no more results.
  var path_602910 = newJObject()
  var query_602911 = newJObject()
  add(path_602910, "AwsAccountId", newJString(AwsAccountId))
  add(path_602910, "Namespace", newJString(Namespace))
  add(path_602910, "UserName", newJString(UserName))
  add(query_602911, "max-results", newJInt(maxResults))
  add(query_602911, "next-token", newJString(nextToken))
  result = call_602909.call(path_602910, query_602911, nil, nil, nil)

var listIAMPolicyAssignmentsForUser* = Call_ListIAMPolicyAssignmentsForUser_602893(
    name: "listIAMPolicyAssignmentsForUser", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}/iam-policy-assignments",
    validator: validate_ListIAMPolicyAssignmentsForUser_602894, base: "/",
    url: url_ListIAMPolicyAssignmentsForUser_602895,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIngestions_602912 = ref object of OpenApiRestCall_601389
proc url_ListIngestions_602914(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListIngestions_602913(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
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
  var valid_602915 = path.getOrDefault("AwsAccountId")
  valid_602915 = validateParameter(valid_602915, JString, required = true,
                                 default = nil)
  if valid_602915 != nil:
    section.add "AwsAccountId", valid_602915
  var valid_602916 = path.getOrDefault("DataSetId")
  valid_602916 = validateParameter(valid_602916, JString, required = true,
                                 default = nil)
  if valid_602916 != nil:
    section.add "DataSetId", valid_602916
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   max-results: JInt
  ##              : The maximum number of results to be returned per request.
  ##   next-token: JString
  ##             : The token for the next set of results, or null if there are no more results.
  section = newJObject()
  var valid_602917 = query.getOrDefault("MaxResults")
  valid_602917 = validateParameter(valid_602917, JString, required = false,
                                 default = nil)
  if valid_602917 != nil:
    section.add "MaxResults", valid_602917
  var valid_602918 = query.getOrDefault("NextToken")
  valid_602918 = validateParameter(valid_602918, JString, required = false,
                                 default = nil)
  if valid_602918 != nil:
    section.add "NextToken", valid_602918
  var valid_602919 = query.getOrDefault("max-results")
  valid_602919 = validateParameter(valid_602919, JInt, required = false, default = nil)
  if valid_602919 != nil:
    section.add "max-results", valid_602919
  var valid_602920 = query.getOrDefault("next-token")
  valid_602920 = validateParameter(valid_602920, JString, required = false,
                                 default = nil)
  if valid_602920 != nil:
    section.add "next-token", valid_602920
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602921 = header.getOrDefault("X-Amz-Signature")
  valid_602921 = validateParameter(valid_602921, JString, required = false,
                                 default = nil)
  if valid_602921 != nil:
    section.add "X-Amz-Signature", valid_602921
  var valid_602922 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602922 = validateParameter(valid_602922, JString, required = false,
                                 default = nil)
  if valid_602922 != nil:
    section.add "X-Amz-Content-Sha256", valid_602922
  var valid_602923 = header.getOrDefault("X-Amz-Date")
  valid_602923 = validateParameter(valid_602923, JString, required = false,
                                 default = nil)
  if valid_602923 != nil:
    section.add "X-Amz-Date", valid_602923
  var valid_602924 = header.getOrDefault("X-Amz-Credential")
  valid_602924 = validateParameter(valid_602924, JString, required = false,
                                 default = nil)
  if valid_602924 != nil:
    section.add "X-Amz-Credential", valid_602924
  var valid_602925 = header.getOrDefault("X-Amz-Security-Token")
  valid_602925 = validateParameter(valid_602925, JString, required = false,
                                 default = nil)
  if valid_602925 != nil:
    section.add "X-Amz-Security-Token", valid_602925
  var valid_602926 = header.getOrDefault("X-Amz-Algorithm")
  valid_602926 = validateParameter(valid_602926, JString, required = false,
                                 default = nil)
  if valid_602926 != nil:
    section.add "X-Amz-Algorithm", valid_602926
  var valid_602927 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602927 = validateParameter(valid_602927, JString, required = false,
                                 default = nil)
  if valid_602927 != nil:
    section.add "X-Amz-SignedHeaders", valid_602927
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602928: Call_ListIngestions_602912; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the history of SPICE ingestions for a dataset.
  ## 
  let valid = call_602928.validator(path, query, header, formData, body)
  let scheme = call_602928.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602928.url(scheme.get, call_602928.host, call_602928.base,
                         call_602928.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602928, url, valid)

proc call*(call_602929: Call_ListIngestions_602912; AwsAccountId: string;
          DataSetId: string; MaxResults: string = ""; NextToken: string = "";
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listIngestions
  ## Lists the history of SPICE ingestions for a dataset.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   DataSetId: string (required)
  ##            : The ID of the dataset used in the ingestion.
  ##   maxResults: int
  ##             : The maximum number of results to be returned per request.
  ##   nextToken: string
  ##            : The token for the next set of results, or null if there are no more results.
  var path_602930 = newJObject()
  var query_602931 = newJObject()
  add(path_602930, "AwsAccountId", newJString(AwsAccountId))
  add(query_602931, "MaxResults", newJString(MaxResults))
  add(query_602931, "NextToken", newJString(NextToken))
  add(path_602930, "DataSetId", newJString(DataSetId))
  add(query_602931, "max-results", newJInt(maxResults))
  add(query_602931, "next-token", newJString(nextToken))
  result = call_602929.call(path_602930, query_602931, nil, nil, nil)

var listIngestions* = Call_ListIngestions_602912(name: "listIngestions",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}/ingestions",
    validator: validate_ListIngestions_602913, base: "/", url: url_ListIngestions_602914,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_602946 = ref object of OpenApiRestCall_601389
proc url_TagResource_602948(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_602947(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_602949 = path.getOrDefault("ResourceArn")
  valid_602949 = validateParameter(valid_602949, JString, required = true,
                                 default = nil)
  if valid_602949 != nil:
    section.add "ResourceArn", valid_602949
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602950 = header.getOrDefault("X-Amz-Signature")
  valid_602950 = validateParameter(valid_602950, JString, required = false,
                                 default = nil)
  if valid_602950 != nil:
    section.add "X-Amz-Signature", valid_602950
  var valid_602951 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602951 = validateParameter(valid_602951, JString, required = false,
                                 default = nil)
  if valid_602951 != nil:
    section.add "X-Amz-Content-Sha256", valid_602951
  var valid_602952 = header.getOrDefault("X-Amz-Date")
  valid_602952 = validateParameter(valid_602952, JString, required = false,
                                 default = nil)
  if valid_602952 != nil:
    section.add "X-Amz-Date", valid_602952
  var valid_602953 = header.getOrDefault("X-Amz-Credential")
  valid_602953 = validateParameter(valid_602953, JString, required = false,
                                 default = nil)
  if valid_602953 != nil:
    section.add "X-Amz-Credential", valid_602953
  var valid_602954 = header.getOrDefault("X-Amz-Security-Token")
  valid_602954 = validateParameter(valid_602954, JString, required = false,
                                 default = nil)
  if valid_602954 != nil:
    section.add "X-Amz-Security-Token", valid_602954
  var valid_602955 = header.getOrDefault("X-Amz-Algorithm")
  valid_602955 = validateParameter(valid_602955, JString, required = false,
                                 default = nil)
  if valid_602955 != nil:
    section.add "X-Amz-Algorithm", valid_602955
  var valid_602956 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602956 = validateParameter(valid_602956, JString, required = false,
                                 default = nil)
  if valid_602956 != nil:
    section.add "X-Amz-SignedHeaders", valid_602956
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602958: Call_TagResource_602946; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Assigns one or more tags (key-value pairs) to the specified QuickSight resource. </p> <p>Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values. You can use the <code>TagResource</code> operation with a resource that already has tags. If you specify a new tag key for the resource, this tag is appended to the list of tags associated with the resource. If you specify a tag key that is already associated with the resource, the new tag value that you specify replaces the previous value for that tag.</p> <p>You can associate as many as 50 tags with a resource. QuickSight supports tagging on data set, data source, dashboard, and template. </p> <p>Tagging for QuickSight works in a similar way to tagging for other AWS services, except for the following:</p> <ul> <li> <p>You can't use tags to track AWS costs for QuickSight. This restriction is because QuickSight costs are based on users and SPICE capacity, which aren't taggable resources.</p> </li> <li> <p>QuickSight doesn't currently support the Tag Editor for AWS Resource Groups.</p> </li> </ul>
  ## 
  let valid = call_602958.validator(path, query, header, formData, body)
  let scheme = call_602958.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602958.url(scheme.get, call_602958.host, call_602958.base,
                         call_602958.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602958, url, valid)

proc call*(call_602959: Call_TagResource_602946; ResourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Assigns one or more tags (key-value pairs) to the specified QuickSight resource. </p> <p>Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values. You can use the <code>TagResource</code> operation with a resource that already has tags. If you specify a new tag key for the resource, this tag is appended to the list of tags associated with the resource. If you specify a tag key that is already associated with the resource, the new tag value that you specify replaces the previous value for that tag.</p> <p>You can associate as many as 50 tags with a resource. QuickSight supports tagging on data set, data source, dashboard, and template. </p> <p>Tagging for QuickSight works in a similar way to tagging for other AWS services, except for the following:</p> <ul> <li> <p>You can't use tags to track AWS costs for QuickSight. This restriction is because QuickSight costs are based on users and SPICE capacity, which aren't taggable resources.</p> </li> <li> <p>QuickSight doesn't currently support the Tag Editor for AWS Resource Groups.</p> </li> </ul>
  ##   ResourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource that you want to tag.
  ##   body: JObject (required)
  var path_602960 = newJObject()
  var body_602961 = newJObject()
  add(path_602960, "ResourceArn", newJString(ResourceArn))
  if body != nil:
    body_602961 = body
  result = call_602959.call(path_602960, nil, nil, nil, body_602961)

var tagResource* = Call_TagResource_602946(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "quicksight.amazonaws.com",
                                        route: "/resources/{ResourceArn}/tags",
                                        validator: validate_TagResource_602947,
                                        base: "/", url: url_TagResource_602948,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_602932 = ref object of OpenApiRestCall_601389
proc url_ListTagsForResource_602934(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_602933(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_602935 = path.getOrDefault("ResourceArn")
  valid_602935 = validateParameter(valid_602935, JString, required = true,
                                 default = nil)
  if valid_602935 != nil:
    section.add "ResourceArn", valid_602935
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602936 = header.getOrDefault("X-Amz-Signature")
  valid_602936 = validateParameter(valid_602936, JString, required = false,
                                 default = nil)
  if valid_602936 != nil:
    section.add "X-Amz-Signature", valid_602936
  var valid_602937 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602937 = validateParameter(valid_602937, JString, required = false,
                                 default = nil)
  if valid_602937 != nil:
    section.add "X-Amz-Content-Sha256", valid_602937
  var valid_602938 = header.getOrDefault("X-Amz-Date")
  valid_602938 = validateParameter(valid_602938, JString, required = false,
                                 default = nil)
  if valid_602938 != nil:
    section.add "X-Amz-Date", valid_602938
  var valid_602939 = header.getOrDefault("X-Amz-Credential")
  valid_602939 = validateParameter(valid_602939, JString, required = false,
                                 default = nil)
  if valid_602939 != nil:
    section.add "X-Amz-Credential", valid_602939
  var valid_602940 = header.getOrDefault("X-Amz-Security-Token")
  valid_602940 = validateParameter(valid_602940, JString, required = false,
                                 default = nil)
  if valid_602940 != nil:
    section.add "X-Amz-Security-Token", valid_602940
  var valid_602941 = header.getOrDefault("X-Amz-Algorithm")
  valid_602941 = validateParameter(valid_602941, JString, required = false,
                                 default = nil)
  if valid_602941 != nil:
    section.add "X-Amz-Algorithm", valid_602941
  var valid_602942 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602942 = validateParameter(valid_602942, JString, required = false,
                                 default = nil)
  if valid_602942 != nil:
    section.add "X-Amz-SignedHeaders", valid_602942
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602943: Call_ListTagsForResource_602932; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags assigned to a resource.
  ## 
  let valid = call_602943.validator(path, query, header, formData, body)
  let scheme = call_602943.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602943.url(scheme.get, call_602943.host, call_602943.base,
                         call_602943.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602943, url, valid)

proc call*(call_602944: Call_ListTagsForResource_602932; ResourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists the tags assigned to a resource.
  ##   ResourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource that you want a list of tags for.
  var path_602945 = newJObject()
  add(path_602945, "ResourceArn", newJString(ResourceArn))
  result = call_602944.call(path_602945, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_602932(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com", route: "/resources/{ResourceArn}/tags",
    validator: validate_ListTagsForResource_602933, base: "/",
    url: url_ListTagsForResource_602934, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTemplateAliases_602962 = ref object of OpenApiRestCall_601389
proc url_ListTemplateAliases_602964(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTemplateAliases_602963(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_602965 = path.getOrDefault("AwsAccountId")
  valid_602965 = validateParameter(valid_602965, JString, required = true,
                                 default = nil)
  if valid_602965 != nil:
    section.add "AwsAccountId", valid_602965
  var valid_602966 = path.getOrDefault("TemplateId")
  valid_602966 = validateParameter(valid_602966, JString, required = true,
                                 default = nil)
  if valid_602966 != nil:
    section.add "TemplateId", valid_602966
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   max-result: JInt
  ##             : The maximum number of results to be returned per request.
  ##   next-token: JString
  ##             : The token for the next set of results, or null if there are no more results.
  section = newJObject()
  var valid_602967 = query.getOrDefault("MaxResults")
  valid_602967 = validateParameter(valid_602967, JString, required = false,
                                 default = nil)
  if valid_602967 != nil:
    section.add "MaxResults", valid_602967
  var valid_602968 = query.getOrDefault("NextToken")
  valid_602968 = validateParameter(valid_602968, JString, required = false,
                                 default = nil)
  if valid_602968 != nil:
    section.add "NextToken", valid_602968
  var valid_602969 = query.getOrDefault("max-result")
  valid_602969 = validateParameter(valid_602969, JInt, required = false, default = nil)
  if valid_602969 != nil:
    section.add "max-result", valid_602969
  var valid_602970 = query.getOrDefault("next-token")
  valid_602970 = validateParameter(valid_602970, JString, required = false,
                                 default = nil)
  if valid_602970 != nil:
    section.add "next-token", valid_602970
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602971 = header.getOrDefault("X-Amz-Signature")
  valid_602971 = validateParameter(valid_602971, JString, required = false,
                                 default = nil)
  if valid_602971 != nil:
    section.add "X-Amz-Signature", valid_602971
  var valid_602972 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602972 = validateParameter(valid_602972, JString, required = false,
                                 default = nil)
  if valid_602972 != nil:
    section.add "X-Amz-Content-Sha256", valid_602972
  var valid_602973 = header.getOrDefault("X-Amz-Date")
  valid_602973 = validateParameter(valid_602973, JString, required = false,
                                 default = nil)
  if valid_602973 != nil:
    section.add "X-Amz-Date", valid_602973
  var valid_602974 = header.getOrDefault("X-Amz-Credential")
  valid_602974 = validateParameter(valid_602974, JString, required = false,
                                 default = nil)
  if valid_602974 != nil:
    section.add "X-Amz-Credential", valid_602974
  var valid_602975 = header.getOrDefault("X-Amz-Security-Token")
  valid_602975 = validateParameter(valid_602975, JString, required = false,
                                 default = nil)
  if valid_602975 != nil:
    section.add "X-Amz-Security-Token", valid_602975
  var valid_602976 = header.getOrDefault("X-Amz-Algorithm")
  valid_602976 = validateParameter(valid_602976, JString, required = false,
                                 default = nil)
  if valid_602976 != nil:
    section.add "X-Amz-Algorithm", valid_602976
  var valid_602977 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602977 = validateParameter(valid_602977, JString, required = false,
                                 default = nil)
  if valid_602977 != nil:
    section.add "X-Amz-SignedHeaders", valid_602977
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602978: Call_ListTemplateAliases_602962; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all the aliases of a template.
  ## 
  let valid = call_602978.validator(path, query, header, formData, body)
  let scheme = call_602978.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602978.url(scheme.get, call_602978.host, call_602978.base,
                         call_602978.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602978, url, valid)

proc call*(call_602979: Call_ListTemplateAliases_602962; AwsAccountId: string;
          TemplateId: string; MaxResults: string = ""; NextToken: string = "";
          maxResult: int = 0; nextToken: string = ""): Recallable =
  ## listTemplateAliases
  ## Lists all the aliases of a template.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the template aliases that you're listing.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResult: int
  ##            : The maximum number of results to be returned per request.
  ##   TemplateId: string (required)
  ##             : The ID for the template.
  ##   nextToken: string
  ##            : The token for the next set of results, or null if there are no more results.
  var path_602980 = newJObject()
  var query_602981 = newJObject()
  add(path_602980, "AwsAccountId", newJString(AwsAccountId))
  add(query_602981, "MaxResults", newJString(MaxResults))
  add(query_602981, "NextToken", newJString(NextToken))
  add(query_602981, "max-result", newJInt(maxResult))
  add(path_602980, "TemplateId", newJString(TemplateId))
  add(query_602981, "next-token", newJString(nextToken))
  result = call_602979.call(path_602980, query_602981, nil, nil, nil)

var listTemplateAliases* = Call_ListTemplateAliases_602962(
    name: "listTemplateAliases", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates/{TemplateId}/aliases",
    validator: validate_ListTemplateAliases_602963, base: "/",
    url: url_ListTemplateAliases_602964, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTemplateVersions_602982 = ref object of OpenApiRestCall_601389
proc url_ListTemplateVersions_602984(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTemplateVersions_602983(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_602985 = path.getOrDefault("AwsAccountId")
  valid_602985 = validateParameter(valid_602985, JString, required = true,
                                 default = nil)
  if valid_602985 != nil:
    section.add "AwsAccountId", valid_602985
  var valid_602986 = path.getOrDefault("TemplateId")
  valid_602986 = validateParameter(valid_602986, JString, required = true,
                                 default = nil)
  if valid_602986 != nil:
    section.add "TemplateId", valid_602986
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   max-results: JInt
  ##              : The maximum number of results to be returned per request.
  ##   next-token: JString
  ##             : The token for the next set of results, or null if there are no more results.
  section = newJObject()
  var valid_602987 = query.getOrDefault("MaxResults")
  valid_602987 = validateParameter(valid_602987, JString, required = false,
                                 default = nil)
  if valid_602987 != nil:
    section.add "MaxResults", valid_602987
  var valid_602988 = query.getOrDefault("NextToken")
  valid_602988 = validateParameter(valid_602988, JString, required = false,
                                 default = nil)
  if valid_602988 != nil:
    section.add "NextToken", valid_602988
  var valid_602989 = query.getOrDefault("max-results")
  valid_602989 = validateParameter(valid_602989, JInt, required = false, default = nil)
  if valid_602989 != nil:
    section.add "max-results", valid_602989
  var valid_602990 = query.getOrDefault("next-token")
  valid_602990 = validateParameter(valid_602990, JString, required = false,
                                 default = nil)
  if valid_602990 != nil:
    section.add "next-token", valid_602990
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602991 = header.getOrDefault("X-Amz-Signature")
  valid_602991 = validateParameter(valid_602991, JString, required = false,
                                 default = nil)
  if valid_602991 != nil:
    section.add "X-Amz-Signature", valid_602991
  var valid_602992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602992 = validateParameter(valid_602992, JString, required = false,
                                 default = nil)
  if valid_602992 != nil:
    section.add "X-Amz-Content-Sha256", valid_602992
  var valid_602993 = header.getOrDefault("X-Amz-Date")
  valid_602993 = validateParameter(valid_602993, JString, required = false,
                                 default = nil)
  if valid_602993 != nil:
    section.add "X-Amz-Date", valid_602993
  var valid_602994 = header.getOrDefault("X-Amz-Credential")
  valid_602994 = validateParameter(valid_602994, JString, required = false,
                                 default = nil)
  if valid_602994 != nil:
    section.add "X-Amz-Credential", valid_602994
  var valid_602995 = header.getOrDefault("X-Amz-Security-Token")
  valid_602995 = validateParameter(valid_602995, JString, required = false,
                                 default = nil)
  if valid_602995 != nil:
    section.add "X-Amz-Security-Token", valid_602995
  var valid_602996 = header.getOrDefault("X-Amz-Algorithm")
  valid_602996 = validateParameter(valid_602996, JString, required = false,
                                 default = nil)
  if valid_602996 != nil:
    section.add "X-Amz-Algorithm", valid_602996
  var valid_602997 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602997 = validateParameter(valid_602997, JString, required = false,
                                 default = nil)
  if valid_602997 != nil:
    section.add "X-Amz-SignedHeaders", valid_602997
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602998: Call_ListTemplateVersions_602982; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all the versions of the templates in the current Amazon QuickSight account.
  ## 
  let valid = call_602998.validator(path, query, header, formData, body)
  let scheme = call_602998.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602998.url(scheme.get, call_602998.host, call_602998.base,
                         call_602998.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602998, url, valid)

proc call*(call_602999: Call_ListTemplateVersions_602982; AwsAccountId: string;
          TemplateId: string; MaxResults: string = ""; NextToken: string = "";
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listTemplateVersions
  ## Lists all the versions of the templates in the current Amazon QuickSight account.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the templates that you're listing.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results to be returned per request.
  ##   TemplateId: string (required)
  ##             : The ID for the template.
  ##   nextToken: string
  ##            : The token for the next set of results, or null if there are no more results.
  var path_603000 = newJObject()
  var query_603001 = newJObject()
  add(path_603000, "AwsAccountId", newJString(AwsAccountId))
  add(query_603001, "MaxResults", newJString(MaxResults))
  add(query_603001, "NextToken", newJString(NextToken))
  add(query_603001, "max-results", newJInt(maxResults))
  add(path_603000, "TemplateId", newJString(TemplateId))
  add(query_603001, "next-token", newJString(nextToken))
  result = call_602999.call(path_603000, query_603001, nil, nil, nil)

var listTemplateVersions* = Call_ListTemplateVersions_602982(
    name: "listTemplateVersions", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates/{TemplateId}/versions",
    validator: validate_ListTemplateVersions_602983, base: "/",
    url: url_ListTemplateVersions_602984, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTemplates_603002 = ref object of OpenApiRestCall_601389
proc url_ListTemplates_603004(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTemplates_603003(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_603005 = path.getOrDefault("AwsAccountId")
  valid_603005 = validateParameter(valid_603005, JString, required = true,
                                 default = nil)
  if valid_603005 != nil:
    section.add "AwsAccountId", valid_603005
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   max-result: JInt
  ##             : The maximum number of results to be returned per request.
  ##   next-token: JString
  ##             : The token for the next set of results, or null if there are no more results.
  section = newJObject()
  var valid_603006 = query.getOrDefault("MaxResults")
  valid_603006 = validateParameter(valid_603006, JString, required = false,
                                 default = nil)
  if valid_603006 != nil:
    section.add "MaxResults", valid_603006
  var valid_603007 = query.getOrDefault("NextToken")
  valid_603007 = validateParameter(valid_603007, JString, required = false,
                                 default = nil)
  if valid_603007 != nil:
    section.add "NextToken", valid_603007
  var valid_603008 = query.getOrDefault("max-result")
  valid_603008 = validateParameter(valid_603008, JInt, required = false, default = nil)
  if valid_603008 != nil:
    section.add "max-result", valid_603008
  var valid_603009 = query.getOrDefault("next-token")
  valid_603009 = validateParameter(valid_603009, JString, required = false,
                                 default = nil)
  if valid_603009 != nil:
    section.add "next-token", valid_603009
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603010 = header.getOrDefault("X-Amz-Signature")
  valid_603010 = validateParameter(valid_603010, JString, required = false,
                                 default = nil)
  if valid_603010 != nil:
    section.add "X-Amz-Signature", valid_603010
  var valid_603011 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603011 = validateParameter(valid_603011, JString, required = false,
                                 default = nil)
  if valid_603011 != nil:
    section.add "X-Amz-Content-Sha256", valid_603011
  var valid_603012 = header.getOrDefault("X-Amz-Date")
  valid_603012 = validateParameter(valid_603012, JString, required = false,
                                 default = nil)
  if valid_603012 != nil:
    section.add "X-Amz-Date", valid_603012
  var valid_603013 = header.getOrDefault("X-Amz-Credential")
  valid_603013 = validateParameter(valid_603013, JString, required = false,
                                 default = nil)
  if valid_603013 != nil:
    section.add "X-Amz-Credential", valid_603013
  var valid_603014 = header.getOrDefault("X-Amz-Security-Token")
  valid_603014 = validateParameter(valid_603014, JString, required = false,
                                 default = nil)
  if valid_603014 != nil:
    section.add "X-Amz-Security-Token", valid_603014
  var valid_603015 = header.getOrDefault("X-Amz-Algorithm")
  valid_603015 = validateParameter(valid_603015, JString, required = false,
                                 default = nil)
  if valid_603015 != nil:
    section.add "X-Amz-Algorithm", valid_603015
  var valid_603016 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603016 = validateParameter(valid_603016, JString, required = false,
                                 default = nil)
  if valid_603016 != nil:
    section.add "X-Amz-SignedHeaders", valid_603016
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603017: Call_ListTemplates_603002; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all the templates in the current Amazon QuickSight account.
  ## 
  let valid = call_603017.validator(path, query, header, formData, body)
  let scheme = call_603017.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603017.url(scheme.get, call_603017.host, call_603017.base,
                         call_603017.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603017, url, valid)

proc call*(call_603018: Call_ListTemplates_603002; AwsAccountId: string;
          MaxResults: string = ""; NextToken: string = ""; maxResult: int = 0;
          nextToken: string = ""): Recallable =
  ## listTemplates
  ## Lists all the templates in the current Amazon QuickSight account.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the templates that you're listing.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResult: int
  ##            : The maximum number of results to be returned per request.
  ##   nextToken: string
  ##            : The token for the next set of results, or null if there are no more results.
  var path_603019 = newJObject()
  var query_603020 = newJObject()
  add(path_603019, "AwsAccountId", newJString(AwsAccountId))
  add(query_603020, "MaxResults", newJString(MaxResults))
  add(query_603020, "NextToken", newJString(NextToken))
  add(query_603020, "max-result", newJInt(maxResult))
  add(query_603020, "next-token", newJString(nextToken))
  result = call_603018.call(path_603019, query_603020, nil, nil, nil)

var listTemplates* = Call_ListTemplates_603002(name: "listTemplates",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates",
    validator: validate_ListTemplates_603003, base: "/", url: url_ListTemplates_603004,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUserGroups_603021 = ref object of OpenApiRestCall_601389
proc url_ListUserGroups_603023(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListUserGroups_603022(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Lists the Amazon QuickSight groups that an Amazon QuickSight user is a member of.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   UserName: JString (required)
  ##           : The Amazon QuickSight user name that you want to list group memberships for.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_603024 = path.getOrDefault("AwsAccountId")
  valid_603024 = validateParameter(valid_603024, JString, required = true,
                                 default = nil)
  if valid_603024 != nil:
    section.add "AwsAccountId", valid_603024
  var valid_603025 = path.getOrDefault("Namespace")
  valid_603025 = validateParameter(valid_603025, JString, required = true,
                                 default = nil)
  if valid_603025 != nil:
    section.add "Namespace", valid_603025
  var valid_603026 = path.getOrDefault("UserName")
  valid_603026 = validateParameter(valid_603026, JString, required = true,
                                 default = nil)
  if valid_603026 != nil:
    section.add "UserName", valid_603026
  result.add "path", section
  ## parameters in `query` object:
  ##   max-results: JInt
  ##              : The maximum number of results to return from this request.
  ##   next-token: JString
  ##             : A pagination token that can be used in a subsequent request.
  section = newJObject()
  var valid_603027 = query.getOrDefault("max-results")
  valid_603027 = validateParameter(valid_603027, JInt, required = false, default = nil)
  if valid_603027 != nil:
    section.add "max-results", valid_603027
  var valid_603028 = query.getOrDefault("next-token")
  valid_603028 = validateParameter(valid_603028, JString, required = false,
                                 default = nil)
  if valid_603028 != nil:
    section.add "next-token", valid_603028
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603029 = header.getOrDefault("X-Amz-Signature")
  valid_603029 = validateParameter(valid_603029, JString, required = false,
                                 default = nil)
  if valid_603029 != nil:
    section.add "X-Amz-Signature", valid_603029
  var valid_603030 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603030 = validateParameter(valid_603030, JString, required = false,
                                 default = nil)
  if valid_603030 != nil:
    section.add "X-Amz-Content-Sha256", valid_603030
  var valid_603031 = header.getOrDefault("X-Amz-Date")
  valid_603031 = validateParameter(valid_603031, JString, required = false,
                                 default = nil)
  if valid_603031 != nil:
    section.add "X-Amz-Date", valid_603031
  var valid_603032 = header.getOrDefault("X-Amz-Credential")
  valid_603032 = validateParameter(valid_603032, JString, required = false,
                                 default = nil)
  if valid_603032 != nil:
    section.add "X-Amz-Credential", valid_603032
  var valid_603033 = header.getOrDefault("X-Amz-Security-Token")
  valid_603033 = validateParameter(valid_603033, JString, required = false,
                                 default = nil)
  if valid_603033 != nil:
    section.add "X-Amz-Security-Token", valid_603033
  var valid_603034 = header.getOrDefault("X-Amz-Algorithm")
  valid_603034 = validateParameter(valid_603034, JString, required = false,
                                 default = nil)
  if valid_603034 != nil:
    section.add "X-Amz-Algorithm", valid_603034
  var valid_603035 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603035 = validateParameter(valid_603035, JString, required = false,
                                 default = nil)
  if valid_603035 != nil:
    section.add "X-Amz-SignedHeaders", valid_603035
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603036: Call_ListUserGroups_603021; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the Amazon QuickSight groups that an Amazon QuickSight user is a member of.
  ## 
  let valid = call_603036.validator(path, query, header, formData, body)
  let scheme = call_603036.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603036.url(scheme.get, call_603036.host, call_603036.base,
                         call_603036.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603036, url, valid)

proc call*(call_603037: Call_ListUserGroups_603021; AwsAccountId: string;
          Namespace: string; UserName: string; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listUserGroups
  ## Lists the Amazon QuickSight groups that an Amazon QuickSight user is a member of.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   UserName: string (required)
  ##           : The Amazon QuickSight user name that you want to list group memberships for.
  ##   maxResults: int
  ##             : The maximum number of results to return from this request.
  ##   nextToken: string
  ##            : A pagination token that can be used in a subsequent request.
  var path_603038 = newJObject()
  var query_603039 = newJObject()
  add(path_603038, "AwsAccountId", newJString(AwsAccountId))
  add(path_603038, "Namespace", newJString(Namespace))
  add(path_603038, "UserName", newJString(UserName))
  add(query_603039, "max-results", newJInt(maxResults))
  add(query_603039, "next-token", newJString(nextToken))
  result = call_603037.call(path_603038, query_603039, nil, nil, nil)

var listUserGroups* = Call_ListUserGroups_603021(name: "listUserGroups",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}/groups",
    validator: validate_ListUserGroups_603022, base: "/", url: url_ListUserGroups_603023,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterUser_603058 = ref object of OpenApiRestCall_601389
proc url_RegisterUser_603060(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_RegisterUser_603059(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_603061 = path.getOrDefault("AwsAccountId")
  valid_603061 = validateParameter(valid_603061, JString, required = true,
                                 default = nil)
  if valid_603061 != nil:
    section.add "AwsAccountId", valid_603061
  var valid_603062 = path.getOrDefault("Namespace")
  valid_603062 = validateParameter(valid_603062, JString, required = true,
                                 default = nil)
  if valid_603062 != nil:
    section.add "Namespace", valid_603062
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603063 = header.getOrDefault("X-Amz-Signature")
  valid_603063 = validateParameter(valid_603063, JString, required = false,
                                 default = nil)
  if valid_603063 != nil:
    section.add "X-Amz-Signature", valid_603063
  var valid_603064 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603064 = validateParameter(valid_603064, JString, required = false,
                                 default = nil)
  if valid_603064 != nil:
    section.add "X-Amz-Content-Sha256", valid_603064
  var valid_603065 = header.getOrDefault("X-Amz-Date")
  valid_603065 = validateParameter(valid_603065, JString, required = false,
                                 default = nil)
  if valid_603065 != nil:
    section.add "X-Amz-Date", valid_603065
  var valid_603066 = header.getOrDefault("X-Amz-Credential")
  valid_603066 = validateParameter(valid_603066, JString, required = false,
                                 default = nil)
  if valid_603066 != nil:
    section.add "X-Amz-Credential", valid_603066
  var valid_603067 = header.getOrDefault("X-Amz-Security-Token")
  valid_603067 = validateParameter(valid_603067, JString, required = false,
                                 default = nil)
  if valid_603067 != nil:
    section.add "X-Amz-Security-Token", valid_603067
  var valid_603068 = header.getOrDefault("X-Amz-Algorithm")
  valid_603068 = validateParameter(valid_603068, JString, required = false,
                                 default = nil)
  if valid_603068 != nil:
    section.add "X-Amz-Algorithm", valid_603068
  var valid_603069 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603069 = validateParameter(valid_603069, JString, required = false,
                                 default = nil)
  if valid_603069 != nil:
    section.add "X-Amz-SignedHeaders", valid_603069
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603071: Call_RegisterUser_603058; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an Amazon QuickSight user, whose identity is associated with the AWS Identity and Access Management (IAM) identity or role specified in the request. 
  ## 
  let valid = call_603071.validator(path, query, header, formData, body)
  let scheme = call_603071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603071.url(scheme.get, call_603071.host, call_603071.base,
                         call_603071.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603071, url, valid)

proc call*(call_603072: Call_RegisterUser_603058; AwsAccountId: string;
          Namespace: string; body: JsonNode): Recallable =
  ## registerUser
  ## Creates an Amazon QuickSight user, whose identity is associated with the AWS Identity and Access Management (IAM) identity or role specified in the request. 
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   body: JObject (required)
  var path_603073 = newJObject()
  var body_603074 = newJObject()
  add(path_603073, "AwsAccountId", newJString(AwsAccountId))
  add(path_603073, "Namespace", newJString(Namespace))
  if body != nil:
    body_603074 = body
  result = call_603072.call(path_603073, nil, nil, nil, body_603074)

var registerUser* = Call_RegisterUser_603058(name: "registerUser",
    meth: HttpMethod.HttpPost, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users",
    validator: validate_RegisterUser_603059, base: "/", url: url_RegisterUser_603060,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsers_603040 = ref object of OpenApiRestCall_601389
proc url_ListUsers_603042(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListUsers_603041(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_603043 = path.getOrDefault("AwsAccountId")
  valid_603043 = validateParameter(valid_603043, JString, required = true,
                                 default = nil)
  if valid_603043 != nil:
    section.add "AwsAccountId", valid_603043
  var valid_603044 = path.getOrDefault("Namespace")
  valid_603044 = validateParameter(valid_603044, JString, required = true,
                                 default = nil)
  if valid_603044 != nil:
    section.add "Namespace", valid_603044
  result.add "path", section
  ## parameters in `query` object:
  ##   max-results: JInt
  ##              : The maximum number of results to return from this request.
  ##   next-token: JString
  ##             : A pagination token that can be used in a subsequent request.
  section = newJObject()
  var valid_603045 = query.getOrDefault("max-results")
  valid_603045 = validateParameter(valid_603045, JInt, required = false, default = nil)
  if valid_603045 != nil:
    section.add "max-results", valid_603045
  var valid_603046 = query.getOrDefault("next-token")
  valid_603046 = validateParameter(valid_603046, JString, required = false,
                                 default = nil)
  if valid_603046 != nil:
    section.add "next-token", valid_603046
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603047 = header.getOrDefault("X-Amz-Signature")
  valid_603047 = validateParameter(valid_603047, JString, required = false,
                                 default = nil)
  if valid_603047 != nil:
    section.add "X-Amz-Signature", valid_603047
  var valid_603048 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603048 = validateParameter(valid_603048, JString, required = false,
                                 default = nil)
  if valid_603048 != nil:
    section.add "X-Amz-Content-Sha256", valid_603048
  var valid_603049 = header.getOrDefault("X-Amz-Date")
  valid_603049 = validateParameter(valid_603049, JString, required = false,
                                 default = nil)
  if valid_603049 != nil:
    section.add "X-Amz-Date", valid_603049
  var valid_603050 = header.getOrDefault("X-Amz-Credential")
  valid_603050 = validateParameter(valid_603050, JString, required = false,
                                 default = nil)
  if valid_603050 != nil:
    section.add "X-Amz-Credential", valid_603050
  var valid_603051 = header.getOrDefault("X-Amz-Security-Token")
  valid_603051 = validateParameter(valid_603051, JString, required = false,
                                 default = nil)
  if valid_603051 != nil:
    section.add "X-Amz-Security-Token", valid_603051
  var valid_603052 = header.getOrDefault("X-Amz-Algorithm")
  valid_603052 = validateParameter(valid_603052, JString, required = false,
                                 default = nil)
  if valid_603052 != nil:
    section.add "X-Amz-Algorithm", valid_603052
  var valid_603053 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603053 = validateParameter(valid_603053, JString, required = false,
                                 default = nil)
  if valid_603053 != nil:
    section.add "X-Amz-SignedHeaders", valid_603053
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603054: Call_ListUsers_603040; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all of the Amazon QuickSight users belonging to this account. 
  ## 
  let valid = call_603054.validator(path, query, header, formData, body)
  let scheme = call_603054.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603054.url(scheme.get, call_603054.host, call_603054.base,
                         call_603054.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603054, url, valid)

proc call*(call_603055: Call_ListUsers_603040; AwsAccountId: string;
          Namespace: string; maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listUsers
  ## Returns a list of all of the Amazon QuickSight users belonging to this account. 
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   maxResults: int
  ##             : The maximum number of results to return from this request.
  ##   nextToken: string
  ##            : A pagination token that can be used in a subsequent request.
  var path_603056 = newJObject()
  var query_603057 = newJObject()
  add(path_603056, "AwsAccountId", newJString(AwsAccountId))
  add(path_603056, "Namespace", newJString(Namespace))
  add(query_603057, "max-results", newJInt(maxResults))
  add(query_603057, "next-token", newJString(nextToken))
  result = call_603055.call(path_603056, query_603057, nil, nil, nil)

var listUsers* = Call_ListUsers_603040(name: "listUsers", meth: HttpMethod.HttpGet,
                                    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users",
                                    validator: validate_ListUsers_603041,
                                    base: "/", url: url_ListUsers_603042,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_603075 = ref object of OpenApiRestCall_601389
proc url_UntagResource_603077(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_603076(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_603078 = path.getOrDefault("ResourceArn")
  valid_603078 = validateParameter(valid_603078, JString, required = true,
                                 default = nil)
  if valid_603078 != nil:
    section.add "ResourceArn", valid_603078
  result.add "path", section
  ## parameters in `query` object:
  ##   keys: JArray (required)
  ##       : The keys of the key-value pairs for the resource tag or tags assigned to the resource.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `keys` field"
  var valid_603079 = query.getOrDefault("keys")
  valid_603079 = validateParameter(valid_603079, JArray, required = true, default = nil)
  if valid_603079 != nil:
    section.add "keys", valid_603079
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603080 = header.getOrDefault("X-Amz-Signature")
  valid_603080 = validateParameter(valid_603080, JString, required = false,
                                 default = nil)
  if valid_603080 != nil:
    section.add "X-Amz-Signature", valid_603080
  var valid_603081 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603081 = validateParameter(valid_603081, JString, required = false,
                                 default = nil)
  if valid_603081 != nil:
    section.add "X-Amz-Content-Sha256", valid_603081
  var valid_603082 = header.getOrDefault("X-Amz-Date")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-Date", valid_603082
  var valid_603083 = header.getOrDefault("X-Amz-Credential")
  valid_603083 = validateParameter(valid_603083, JString, required = false,
                                 default = nil)
  if valid_603083 != nil:
    section.add "X-Amz-Credential", valid_603083
  var valid_603084 = header.getOrDefault("X-Amz-Security-Token")
  valid_603084 = validateParameter(valid_603084, JString, required = false,
                                 default = nil)
  if valid_603084 != nil:
    section.add "X-Amz-Security-Token", valid_603084
  var valid_603085 = header.getOrDefault("X-Amz-Algorithm")
  valid_603085 = validateParameter(valid_603085, JString, required = false,
                                 default = nil)
  if valid_603085 != nil:
    section.add "X-Amz-Algorithm", valid_603085
  var valid_603086 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603086 = validateParameter(valid_603086, JString, required = false,
                                 default = nil)
  if valid_603086 != nil:
    section.add "X-Amz-SignedHeaders", valid_603086
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603087: Call_UntagResource_603075; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a tag or tags from a resource.
  ## 
  let valid = call_603087.validator(path, query, header, formData, body)
  let scheme = call_603087.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603087.url(scheme.get, call_603087.host, call_603087.base,
                         call_603087.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603087, url, valid)

proc call*(call_603088: Call_UntagResource_603075; keys: JsonNode;
          ResourceArn: string): Recallable =
  ## untagResource
  ## Removes a tag or tags from a resource.
  ##   keys: JArray (required)
  ##       : The keys of the key-value pairs for the resource tag or tags assigned to the resource.
  ##   ResourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource that you want to untag.
  var path_603089 = newJObject()
  var query_603090 = newJObject()
  if keys != nil:
    query_603090.add "keys", keys
  add(path_603089, "ResourceArn", newJString(ResourceArn))
  result = call_603088.call(path_603089, query_603090, nil, nil, nil)

var untagResource* = Call_UntagResource_603075(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "quicksight.amazonaws.com",
    route: "/resources/{ResourceArn}/tags#keys",
    validator: validate_UntagResource_603076, base: "/", url: url_UntagResource_603077,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDashboardPublishedVersion_603091 = ref object of OpenApiRestCall_601389
proc url_UpdateDashboardPublishedVersion_603093(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDashboardPublishedVersion_603092(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the published version of a dashboard.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account that contains the dashboard that you're updating.
  ##   VersionNumber: JInt (required)
  ##                : The version number of the dashboard.
  ##   DashboardId: JString (required)
  ##              : The ID for the dashboard.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_603094 = path.getOrDefault("AwsAccountId")
  valid_603094 = validateParameter(valid_603094, JString, required = true,
                                 default = nil)
  if valid_603094 != nil:
    section.add "AwsAccountId", valid_603094
  var valid_603095 = path.getOrDefault("VersionNumber")
  valid_603095 = validateParameter(valid_603095, JInt, required = true, default = nil)
  if valid_603095 != nil:
    section.add "VersionNumber", valid_603095
  var valid_603096 = path.getOrDefault("DashboardId")
  valid_603096 = validateParameter(valid_603096, JString, required = true,
                                 default = nil)
  if valid_603096 != nil:
    section.add "DashboardId", valid_603096
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603097 = header.getOrDefault("X-Amz-Signature")
  valid_603097 = validateParameter(valid_603097, JString, required = false,
                                 default = nil)
  if valid_603097 != nil:
    section.add "X-Amz-Signature", valid_603097
  var valid_603098 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603098 = validateParameter(valid_603098, JString, required = false,
                                 default = nil)
  if valid_603098 != nil:
    section.add "X-Amz-Content-Sha256", valid_603098
  var valid_603099 = header.getOrDefault("X-Amz-Date")
  valid_603099 = validateParameter(valid_603099, JString, required = false,
                                 default = nil)
  if valid_603099 != nil:
    section.add "X-Amz-Date", valid_603099
  var valid_603100 = header.getOrDefault("X-Amz-Credential")
  valid_603100 = validateParameter(valid_603100, JString, required = false,
                                 default = nil)
  if valid_603100 != nil:
    section.add "X-Amz-Credential", valid_603100
  var valid_603101 = header.getOrDefault("X-Amz-Security-Token")
  valid_603101 = validateParameter(valid_603101, JString, required = false,
                                 default = nil)
  if valid_603101 != nil:
    section.add "X-Amz-Security-Token", valid_603101
  var valid_603102 = header.getOrDefault("X-Amz-Algorithm")
  valid_603102 = validateParameter(valid_603102, JString, required = false,
                                 default = nil)
  if valid_603102 != nil:
    section.add "X-Amz-Algorithm", valid_603102
  var valid_603103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603103 = validateParameter(valid_603103, JString, required = false,
                                 default = nil)
  if valid_603103 != nil:
    section.add "X-Amz-SignedHeaders", valid_603103
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603104: Call_UpdateDashboardPublishedVersion_603091;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Updates the published version of a dashboard.
  ## 
  let valid = call_603104.validator(path, query, header, formData, body)
  let scheme = call_603104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603104.url(scheme.get, call_603104.host, call_603104.base,
                         call_603104.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603104, url, valid)

proc call*(call_603105: Call_UpdateDashboardPublishedVersion_603091;
          AwsAccountId: string; VersionNumber: int; DashboardId: string): Recallable =
  ## updateDashboardPublishedVersion
  ## Updates the published version of a dashboard.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the dashboard that you're updating.
  ##   VersionNumber: int (required)
  ##                : The version number of the dashboard.
  ##   DashboardId: string (required)
  ##              : The ID for the dashboard.
  var path_603106 = newJObject()
  add(path_603106, "AwsAccountId", newJString(AwsAccountId))
  add(path_603106, "VersionNumber", newJInt(VersionNumber))
  add(path_603106, "DashboardId", newJString(DashboardId))
  result = call_603105.call(path_603106, nil, nil, nil, nil)

var updateDashboardPublishedVersion* = Call_UpdateDashboardPublishedVersion_603091(
    name: "updateDashboardPublishedVersion", meth: HttpMethod.HttpPut,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}/versions/{VersionNumber}",
    validator: validate_UpdateDashboardPublishedVersion_603092, base: "/",
    url: url_UpdateDashboardPublishedVersion_603093,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.atozSign(input.getOrDefault("query"), SHA256)

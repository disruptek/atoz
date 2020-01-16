
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon EC2 Container Registry
## version: 2015-09-21
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon Elastic Container Registry</fullname> <p>Amazon Elastic Container Registry (Amazon ECR) is a managed Docker registry service. Customers can use the familiar Docker CLI to push, pull, and manage images. Amazon ECR provides a secure, scalable, and reliable registry. Amazon ECR supports private Docker repositories with resource-based permissions using IAM so that specific users or Amazon EC2 instances can access repositories and images. Developers can use the Docker CLI to author and manage images.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/ecr/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "api.ecr.ap-northeast-1.amazonaws.com", "ap-southeast-1": "api.ecr.ap-southeast-1.amazonaws.com",
                           "us-west-2": "api.ecr.us-west-2.amazonaws.com",
                           "eu-west-2": "api.ecr.eu-west-2.amazonaws.com", "ap-northeast-3": "api.ecr.ap-northeast-3.amazonaws.com", "eu-central-1": "api.ecr.eu-central-1.amazonaws.com",
                           "us-east-2": "api.ecr.us-east-2.amazonaws.com",
                           "us-east-1": "api.ecr.us-east-1.amazonaws.com", "cn-northwest-1": "api.ecr.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "api.ecr.ap-south-1.amazonaws.com",
                           "eu-north-1": "api.ecr.eu-north-1.amazonaws.com", "ap-northeast-2": "api.ecr.ap-northeast-2.amazonaws.com",
                           "us-west-1": "api.ecr.us-west-1.amazonaws.com", "us-gov-east-1": "api.ecr.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "api.ecr.eu-west-3.amazonaws.com",
                           "cn-north-1": "api.ecr.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "api.ecr.sa-east-1.amazonaws.com",
                           "eu-west-1": "api.ecr.eu-west-1.amazonaws.com", "us-gov-west-1": "api.ecr.us-gov-west-1.amazonaws.com", "ap-southeast-2": "api.ecr.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "api.ecr.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "api.ecr.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "api.ecr.ap-southeast-1.amazonaws.com",
      "us-west-2": "api.ecr.us-west-2.amazonaws.com",
      "eu-west-2": "api.ecr.eu-west-2.amazonaws.com",
      "ap-northeast-3": "api.ecr.ap-northeast-3.amazonaws.com",
      "eu-central-1": "api.ecr.eu-central-1.amazonaws.com",
      "us-east-2": "api.ecr.us-east-2.amazonaws.com",
      "us-east-1": "api.ecr.us-east-1.amazonaws.com",
      "cn-northwest-1": "api.ecr.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "api.ecr.ap-south-1.amazonaws.com",
      "eu-north-1": "api.ecr.eu-north-1.amazonaws.com",
      "ap-northeast-2": "api.ecr.ap-northeast-2.amazonaws.com",
      "us-west-1": "api.ecr.us-west-1.amazonaws.com",
      "us-gov-east-1": "api.ecr.us-gov-east-1.amazonaws.com",
      "eu-west-3": "api.ecr.eu-west-3.amazonaws.com",
      "cn-north-1": "api.ecr.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "api.ecr.sa-east-1.amazonaws.com",
      "eu-west-1": "api.ecr.eu-west-1.amazonaws.com",
      "us-gov-west-1": "api.ecr.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "api.ecr.ap-southeast-2.amazonaws.com",
      "ca-central-1": "api.ecr.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "ecr"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_BatchCheckLayerAvailability_605927 = ref object of OpenApiRestCall_605589
proc url_BatchCheckLayerAvailability_605929(protocol: Scheme; host: string;
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

proc validate_BatchCheckLayerAvailability_605928(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Check the availability of multiple image layers in a specified registry and repository.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
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
      "AmazonEC2ContainerRegistry_V20150921.BatchCheckLayerAvailability"))
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

proc call*(call_606085: Call_BatchCheckLayerAvailability_605927; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Check the availability of multiple image layers in a specified registry and repository.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ## 
  let valid = call_606085.validator(path, query, header, formData, body)
  let scheme = call_606085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606085.url(scheme.get, call_606085.host, call_606085.base,
                         call_606085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606085, url, valid)

proc call*(call_606156: Call_BatchCheckLayerAvailability_605927; body: JsonNode): Recallable =
  ## batchCheckLayerAvailability
  ## <p>Check the availability of multiple image layers in a specified registry and repository.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ##   body: JObject (required)
  var body_606157 = newJObject()
  if body != nil:
    body_606157 = body
  result = call_606156.call(nil, nil, nil, nil, body_606157)

var batchCheckLayerAvailability* = Call_BatchCheckLayerAvailability_605927(
    name: "batchCheckLayerAvailability", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.BatchCheckLayerAvailability",
    validator: validate_BatchCheckLayerAvailability_605928, base: "/",
    url: url_BatchCheckLayerAvailability_605929,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeleteImage_606196 = ref object of OpenApiRestCall_605589
proc url_BatchDeleteImage_606198(protocol: Scheme; host: string; base: string;
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

proc validate_BatchDeleteImage_606197(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Deletes a list of specified images within a specified repository. Images are specified with either <code>imageTag</code> or <code>imageDigest</code>.</p> <p>You can remove a tag from an image by specifying the image's tag in your request. When you remove the last tag from an image, the image is deleted from your repository.</p> <p>You can completely delete an image (and all of its tags) by specifying the image's digest in your request.</p>
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
      "AmazonEC2ContainerRegistry_V20150921.BatchDeleteImage"))
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

proc call*(call_606208: Call_BatchDeleteImage_606196; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a list of specified images within a specified repository. Images are specified with either <code>imageTag</code> or <code>imageDigest</code>.</p> <p>You can remove a tag from an image by specifying the image's tag in your request. When you remove the last tag from an image, the image is deleted from your repository.</p> <p>You can completely delete an image (and all of its tags) by specifying the image's digest in your request.</p>
  ## 
  let valid = call_606208.validator(path, query, header, formData, body)
  let scheme = call_606208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606208.url(scheme.get, call_606208.host, call_606208.base,
                         call_606208.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606208, url, valid)

proc call*(call_606209: Call_BatchDeleteImage_606196; body: JsonNode): Recallable =
  ## batchDeleteImage
  ## <p>Deletes a list of specified images within a specified repository. Images are specified with either <code>imageTag</code> or <code>imageDigest</code>.</p> <p>You can remove a tag from an image by specifying the image's tag in your request. When you remove the last tag from an image, the image is deleted from your repository.</p> <p>You can completely delete an image (and all of its tags) by specifying the image's digest in your request.</p>
  ##   body: JObject (required)
  var body_606210 = newJObject()
  if body != nil:
    body_606210 = body
  result = call_606209.call(nil, nil, nil, nil, body_606210)

var batchDeleteImage* = Call_BatchDeleteImage_606196(name: "batchDeleteImage",
    meth: HttpMethod.HttpPost, host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.BatchDeleteImage",
    validator: validate_BatchDeleteImage_606197, base: "/",
    url: url_BatchDeleteImage_606198, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetImage_606211 = ref object of OpenApiRestCall_605589
proc url_BatchGetImage_606213(protocol: Scheme; host: string; base: string;
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

proc validate_BatchGetImage_606212(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets detailed information for specified images within a specified repository. Images are specified with either <code>imageTag</code> or <code>imageDigest</code>.
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
      "AmazonEC2ContainerRegistry_V20150921.BatchGetImage"))
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

proc call*(call_606223: Call_BatchGetImage_606211; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets detailed information for specified images within a specified repository. Images are specified with either <code>imageTag</code> or <code>imageDigest</code>.
  ## 
  let valid = call_606223.validator(path, query, header, formData, body)
  let scheme = call_606223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606223.url(scheme.get, call_606223.host, call_606223.base,
                         call_606223.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606223, url, valid)

proc call*(call_606224: Call_BatchGetImage_606211; body: JsonNode): Recallable =
  ## batchGetImage
  ## Gets detailed information for specified images within a specified repository. Images are specified with either <code>imageTag</code> or <code>imageDigest</code>.
  ##   body: JObject (required)
  var body_606225 = newJObject()
  if body != nil:
    body_606225 = body
  result = call_606224.call(nil, nil, nil, nil, body_606225)

var batchGetImage* = Call_BatchGetImage_606211(name: "batchGetImage",
    meth: HttpMethod.HttpPost, host: "api.ecr.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.BatchGetImage",
    validator: validate_BatchGetImage_606212, base: "/", url: url_BatchGetImage_606213,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CompleteLayerUpload_606226 = ref object of OpenApiRestCall_605589
proc url_CompleteLayerUpload_606228(protocol: Scheme; host: string; base: string;
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

proc validate_CompleteLayerUpload_606227(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Informs Amazon ECR that the image layer upload has completed for a specified registry, repository name, and upload ID. You can optionally provide a <code>sha256</code> digest of the image layer for data validation purposes.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
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
      "AmazonEC2ContainerRegistry_V20150921.CompleteLayerUpload"))
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

proc call*(call_606238: Call_CompleteLayerUpload_606226; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Informs Amazon ECR that the image layer upload has completed for a specified registry, repository name, and upload ID. You can optionally provide a <code>sha256</code> digest of the image layer for data validation purposes.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ## 
  let valid = call_606238.validator(path, query, header, formData, body)
  let scheme = call_606238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606238.url(scheme.get, call_606238.host, call_606238.base,
                         call_606238.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606238, url, valid)

proc call*(call_606239: Call_CompleteLayerUpload_606226; body: JsonNode): Recallable =
  ## completeLayerUpload
  ## <p>Informs Amazon ECR that the image layer upload has completed for a specified registry, repository name, and upload ID. You can optionally provide a <code>sha256</code> digest of the image layer for data validation purposes.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ##   body: JObject (required)
  var body_606240 = newJObject()
  if body != nil:
    body_606240 = body
  result = call_606239.call(nil, nil, nil, nil, body_606240)

var completeLayerUpload* = Call_CompleteLayerUpload_606226(
    name: "completeLayerUpload", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.CompleteLayerUpload",
    validator: validate_CompleteLayerUpload_606227, base: "/",
    url: url_CompleteLayerUpload_606228, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRepository_606241 = ref object of OpenApiRestCall_605589
proc url_CreateRepository_606243(protocol: Scheme; host: string; base: string;
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

proc validate_CreateRepository_606242(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Creates an Amazon Elastic Container Registry (Amazon ECR) repository, where users can push and pull Docker images. For more information, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/Repositories.html">Amazon ECR Repositories</a> in the <i>Amazon Elastic Container Registry User Guide</i>.
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
      "AmazonEC2ContainerRegistry_V20150921.CreateRepository"))
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

proc call*(call_606253: Call_CreateRepository_606241; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an Amazon Elastic Container Registry (Amazon ECR) repository, where users can push and pull Docker images. For more information, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/Repositories.html">Amazon ECR Repositories</a> in the <i>Amazon Elastic Container Registry User Guide</i>.
  ## 
  let valid = call_606253.validator(path, query, header, formData, body)
  let scheme = call_606253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606253.url(scheme.get, call_606253.host, call_606253.base,
                         call_606253.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606253, url, valid)

proc call*(call_606254: Call_CreateRepository_606241; body: JsonNode): Recallable =
  ## createRepository
  ## Creates an Amazon Elastic Container Registry (Amazon ECR) repository, where users can push and pull Docker images. For more information, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/Repositories.html">Amazon ECR Repositories</a> in the <i>Amazon Elastic Container Registry User Guide</i>.
  ##   body: JObject (required)
  var body_606255 = newJObject()
  if body != nil:
    body_606255 = body
  result = call_606254.call(nil, nil, nil, nil, body_606255)

var createRepository* = Call_CreateRepository_606241(name: "createRepository",
    meth: HttpMethod.HttpPost, host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.CreateRepository",
    validator: validate_CreateRepository_606242, base: "/",
    url: url_CreateRepository_606243, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLifecyclePolicy_606256 = ref object of OpenApiRestCall_605589
proc url_DeleteLifecyclePolicy_606258(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteLifecyclePolicy_606257(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the specified lifecycle policy.
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
      "AmazonEC2ContainerRegistry_V20150921.DeleteLifecyclePolicy"))
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

proc call*(call_606268: Call_DeleteLifecyclePolicy_606256; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified lifecycle policy.
  ## 
  let valid = call_606268.validator(path, query, header, formData, body)
  let scheme = call_606268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606268.url(scheme.get, call_606268.host, call_606268.base,
                         call_606268.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606268, url, valid)

proc call*(call_606269: Call_DeleteLifecyclePolicy_606256; body: JsonNode): Recallable =
  ## deleteLifecyclePolicy
  ## Deletes the specified lifecycle policy.
  ##   body: JObject (required)
  var body_606270 = newJObject()
  if body != nil:
    body_606270 = body
  result = call_606269.call(nil, nil, nil, nil, body_606270)

var deleteLifecyclePolicy* = Call_DeleteLifecyclePolicy_606256(
    name: "deleteLifecyclePolicy", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.DeleteLifecyclePolicy",
    validator: validate_DeleteLifecyclePolicy_606257, base: "/",
    url: url_DeleteLifecyclePolicy_606258, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRepository_606271 = ref object of OpenApiRestCall_605589
proc url_DeleteRepository_606273(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteRepository_606272(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Deletes an existing image repository. If a repository contains images, you must use the <code>force</code> option to delete it.
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
  var valid_606274 = header.getOrDefault("X-Amz-Target")
  valid_606274 = validateParameter(valid_606274, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.DeleteRepository"))
  if valid_606274 != nil:
    section.add "X-Amz-Target", valid_606274
  var valid_606275 = header.getOrDefault("X-Amz-Signature")
  valid_606275 = validateParameter(valid_606275, JString, required = false,
                                 default = nil)
  if valid_606275 != nil:
    section.add "X-Amz-Signature", valid_606275
  var valid_606276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606276 = validateParameter(valid_606276, JString, required = false,
                                 default = nil)
  if valid_606276 != nil:
    section.add "X-Amz-Content-Sha256", valid_606276
  var valid_606277 = header.getOrDefault("X-Amz-Date")
  valid_606277 = validateParameter(valid_606277, JString, required = false,
                                 default = nil)
  if valid_606277 != nil:
    section.add "X-Amz-Date", valid_606277
  var valid_606278 = header.getOrDefault("X-Amz-Credential")
  valid_606278 = validateParameter(valid_606278, JString, required = false,
                                 default = nil)
  if valid_606278 != nil:
    section.add "X-Amz-Credential", valid_606278
  var valid_606279 = header.getOrDefault("X-Amz-Security-Token")
  valid_606279 = validateParameter(valid_606279, JString, required = false,
                                 default = nil)
  if valid_606279 != nil:
    section.add "X-Amz-Security-Token", valid_606279
  var valid_606280 = header.getOrDefault("X-Amz-Algorithm")
  valid_606280 = validateParameter(valid_606280, JString, required = false,
                                 default = nil)
  if valid_606280 != nil:
    section.add "X-Amz-Algorithm", valid_606280
  var valid_606281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606281 = validateParameter(valid_606281, JString, required = false,
                                 default = nil)
  if valid_606281 != nil:
    section.add "X-Amz-SignedHeaders", valid_606281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606283: Call_DeleteRepository_606271; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing image repository. If a repository contains images, you must use the <code>force</code> option to delete it.
  ## 
  let valid = call_606283.validator(path, query, header, formData, body)
  let scheme = call_606283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606283.url(scheme.get, call_606283.host, call_606283.base,
                         call_606283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606283, url, valid)

proc call*(call_606284: Call_DeleteRepository_606271; body: JsonNode): Recallable =
  ## deleteRepository
  ## Deletes an existing image repository. If a repository contains images, you must use the <code>force</code> option to delete it.
  ##   body: JObject (required)
  var body_606285 = newJObject()
  if body != nil:
    body_606285 = body
  result = call_606284.call(nil, nil, nil, nil, body_606285)

var deleteRepository* = Call_DeleteRepository_606271(name: "deleteRepository",
    meth: HttpMethod.HttpPost, host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.DeleteRepository",
    validator: validate_DeleteRepository_606272, base: "/",
    url: url_DeleteRepository_606273, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRepositoryPolicy_606286 = ref object of OpenApiRestCall_605589
proc url_DeleteRepositoryPolicy_606288(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteRepositoryPolicy_606287(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the repository policy from a specified repository.
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
  var valid_606289 = header.getOrDefault("X-Amz-Target")
  valid_606289 = validateParameter(valid_606289, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.DeleteRepositoryPolicy"))
  if valid_606289 != nil:
    section.add "X-Amz-Target", valid_606289
  var valid_606290 = header.getOrDefault("X-Amz-Signature")
  valid_606290 = validateParameter(valid_606290, JString, required = false,
                                 default = nil)
  if valid_606290 != nil:
    section.add "X-Amz-Signature", valid_606290
  var valid_606291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606291 = validateParameter(valid_606291, JString, required = false,
                                 default = nil)
  if valid_606291 != nil:
    section.add "X-Amz-Content-Sha256", valid_606291
  var valid_606292 = header.getOrDefault("X-Amz-Date")
  valid_606292 = validateParameter(valid_606292, JString, required = false,
                                 default = nil)
  if valid_606292 != nil:
    section.add "X-Amz-Date", valid_606292
  var valid_606293 = header.getOrDefault("X-Amz-Credential")
  valid_606293 = validateParameter(valid_606293, JString, required = false,
                                 default = nil)
  if valid_606293 != nil:
    section.add "X-Amz-Credential", valid_606293
  var valid_606294 = header.getOrDefault("X-Amz-Security-Token")
  valid_606294 = validateParameter(valid_606294, JString, required = false,
                                 default = nil)
  if valid_606294 != nil:
    section.add "X-Amz-Security-Token", valid_606294
  var valid_606295 = header.getOrDefault("X-Amz-Algorithm")
  valid_606295 = validateParameter(valid_606295, JString, required = false,
                                 default = nil)
  if valid_606295 != nil:
    section.add "X-Amz-Algorithm", valid_606295
  var valid_606296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606296 = validateParameter(valid_606296, JString, required = false,
                                 default = nil)
  if valid_606296 != nil:
    section.add "X-Amz-SignedHeaders", valid_606296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606298: Call_DeleteRepositoryPolicy_606286; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the repository policy from a specified repository.
  ## 
  let valid = call_606298.validator(path, query, header, formData, body)
  let scheme = call_606298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606298.url(scheme.get, call_606298.host, call_606298.base,
                         call_606298.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606298, url, valid)

proc call*(call_606299: Call_DeleteRepositoryPolicy_606286; body: JsonNode): Recallable =
  ## deleteRepositoryPolicy
  ## Deletes the repository policy from a specified repository.
  ##   body: JObject (required)
  var body_606300 = newJObject()
  if body != nil:
    body_606300 = body
  result = call_606299.call(nil, nil, nil, nil, body_606300)

var deleteRepositoryPolicy* = Call_DeleteRepositoryPolicy_606286(
    name: "deleteRepositoryPolicy", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.DeleteRepositoryPolicy",
    validator: validate_DeleteRepositoryPolicy_606287, base: "/",
    url: url_DeleteRepositoryPolicy_606288, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeImageScanFindings_606301 = ref object of OpenApiRestCall_605589
proc url_DescribeImageScanFindings_606303(protocol: Scheme; host: string;
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

proc validate_DescribeImageScanFindings_606302(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the image scan findings for the specified image.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_606304 = query.getOrDefault("nextToken")
  valid_606304 = validateParameter(valid_606304, JString, required = false,
                                 default = nil)
  if valid_606304 != nil:
    section.add "nextToken", valid_606304
  var valid_606305 = query.getOrDefault("maxResults")
  valid_606305 = validateParameter(valid_606305, JString, required = false,
                                 default = nil)
  if valid_606305 != nil:
    section.add "maxResults", valid_606305
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
  var valid_606306 = header.getOrDefault("X-Amz-Target")
  valid_606306 = validateParameter(valid_606306, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.DescribeImageScanFindings"))
  if valid_606306 != nil:
    section.add "X-Amz-Target", valid_606306
  var valid_606307 = header.getOrDefault("X-Amz-Signature")
  valid_606307 = validateParameter(valid_606307, JString, required = false,
                                 default = nil)
  if valid_606307 != nil:
    section.add "X-Amz-Signature", valid_606307
  var valid_606308 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606308 = validateParameter(valid_606308, JString, required = false,
                                 default = nil)
  if valid_606308 != nil:
    section.add "X-Amz-Content-Sha256", valid_606308
  var valid_606309 = header.getOrDefault("X-Amz-Date")
  valid_606309 = validateParameter(valid_606309, JString, required = false,
                                 default = nil)
  if valid_606309 != nil:
    section.add "X-Amz-Date", valid_606309
  var valid_606310 = header.getOrDefault("X-Amz-Credential")
  valid_606310 = validateParameter(valid_606310, JString, required = false,
                                 default = nil)
  if valid_606310 != nil:
    section.add "X-Amz-Credential", valid_606310
  var valid_606311 = header.getOrDefault("X-Amz-Security-Token")
  valid_606311 = validateParameter(valid_606311, JString, required = false,
                                 default = nil)
  if valid_606311 != nil:
    section.add "X-Amz-Security-Token", valid_606311
  var valid_606312 = header.getOrDefault("X-Amz-Algorithm")
  valid_606312 = validateParameter(valid_606312, JString, required = false,
                                 default = nil)
  if valid_606312 != nil:
    section.add "X-Amz-Algorithm", valid_606312
  var valid_606313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606313 = validateParameter(valid_606313, JString, required = false,
                                 default = nil)
  if valid_606313 != nil:
    section.add "X-Amz-SignedHeaders", valid_606313
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606315: Call_DescribeImageScanFindings_606301; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the image scan findings for the specified image.
  ## 
  let valid = call_606315.validator(path, query, header, formData, body)
  let scheme = call_606315.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606315.url(scheme.get, call_606315.host, call_606315.base,
                         call_606315.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606315, url, valid)

proc call*(call_606316: Call_DescribeImageScanFindings_606301; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## describeImageScanFindings
  ## Describes the image scan findings for the specified image.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606317 = newJObject()
  var body_606318 = newJObject()
  add(query_606317, "nextToken", newJString(nextToken))
  if body != nil:
    body_606318 = body
  add(query_606317, "maxResults", newJString(maxResults))
  result = call_606316.call(nil, query_606317, nil, nil, body_606318)

var describeImageScanFindings* = Call_DescribeImageScanFindings_606301(
    name: "describeImageScanFindings", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.DescribeImageScanFindings",
    validator: validate_DescribeImageScanFindings_606302, base: "/",
    url: url_DescribeImageScanFindings_606303,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeImages_606320 = ref object of OpenApiRestCall_605589
proc url_DescribeImages_606322(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeImages_606321(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Returns metadata about the images in a repository, including image size, image tags, and creation date.</p> <note> <p>Beginning with Docker version 1.9, the Docker client compresses image layers before pushing them to a V2 Docker registry. The output of the <code>docker images</code> command shows the uncompressed image size, so it may return a larger image size than the image sizes returned by <a>DescribeImages</a>.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_606323 = query.getOrDefault("nextToken")
  valid_606323 = validateParameter(valid_606323, JString, required = false,
                                 default = nil)
  if valid_606323 != nil:
    section.add "nextToken", valid_606323
  var valid_606324 = query.getOrDefault("maxResults")
  valid_606324 = validateParameter(valid_606324, JString, required = false,
                                 default = nil)
  if valid_606324 != nil:
    section.add "maxResults", valid_606324
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
  var valid_606325 = header.getOrDefault("X-Amz-Target")
  valid_606325 = validateParameter(valid_606325, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.DescribeImages"))
  if valid_606325 != nil:
    section.add "X-Amz-Target", valid_606325
  var valid_606326 = header.getOrDefault("X-Amz-Signature")
  valid_606326 = validateParameter(valid_606326, JString, required = false,
                                 default = nil)
  if valid_606326 != nil:
    section.add "X-Amz-Signature", valid_606326
  var valid_606327 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606327 = validateParameter(valid_606327, JString, required = false,
                                 default = nil)
  if valid_606327 != nil:
    section.add "X-Amz-Content-Sha256", valid_606327
  var valid_606328 = header.getOrDefault("X-Amz-Date")
  valid_606328 = validateParameter(valid_606328, JString, required = false,
                                 default = nil)
  if valid_606328 != nil:
    section.add "X-Amz-Date", valid_606328
  var valid_606329 = header.getOrDefault("X-Amz-Credential")
  valid_606329 = validateParameter(valid_606329, JString, required = false,
                                 default = nil)
  if valid_606329 != nil:
    section.add "X-Amz-Credential", valid_606329
  var valid_606330 = header.getOrDefault("X-Amz-Security-Token")
  valid_606330 = validateParameter(valid_606330, JString, required = false,
                                 default = nil)
  if valid_606330 != nil:
    section.add "X-Amz-Security-Token", valid_606330
  var valid_606331 = header.getOrDefault("X-Amz-Algorithm")
  valid_606331 = validateParameter(valid_606331, JString, required = false,
                                 default = nil)
  if valid_606331 != nil:
    section.add "X-Amz-Algorithm", valid_606331
  var valid_606332 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606332 = validateParameter(valid_606332, JString, required = false,
                                 default = nil)
  if valid_606332 != nil:
    section.add "X-Amz-SignedHeaders", valid_606332
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606334: Call_DescribeImages_606320; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns metadata about the images in a repository, including image size, image tags, and creation date.</p> <note> <p>Beginning with Docker version 1.9, the Docker client compresses image layers before pushing them to a V2 Docker registry. The output of the <code>docker images</code> command shows the uncompressed image size, so it may return a larger image size than the image sizes returned by <a>DescribeImages</a>.</p> </note>
  ## 
  let valid = call_606334.validator(path, query, header, formData, body)
  let scheme = call_606334.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606334.url(scheme.get, call_606334.host, call_606334.base,
                         call_606334.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606334, url, valid)

proc call*(call_606335: Call_DescribeImages_606320; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## describeImages
  ## <p>Returns metadata about the images in a repository, including image size, image tags, and creation date.</p> <note> <p>Beginning with Docker version 1.9, the Docker client compresses image layers before pushing them to a V2 Docker registry. The output of the <code>docker images</code> command shows the uncompressed image size, so it may return a larger image size than the image sizes returned by <a>DescribeImages</a>.</p> </note>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606336 = newJObject()
  var body_606337 = newJObject()
  add(query_606336, "nextToken", newJString(nextToken))
  if body != nil:
    body_606337 = body
  add(query_606336, "maxResults", newJString(maxResults))
  result = call_606335.call(nil, query_606336, nil, nil, body_606337)

var describeImages* = Call_DescribeImages_606320(name: "describeImages",
    meth: HttpMethod.HttpPost, host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.DescribeImages",
    validator: validate_DescribeImages_606321, base: "/", url: url_DescribeImages_606322,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRepositories_606338 = ref object of OpenApiRestCall_605589
proc url_DescribeRepositories_606340(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeRepositories_606339(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes image repositories in a registry.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_606341 = query.getOrDefault("nextToken")
  valid_606341 = validateParameter(valid_606341, JString, required = false,
                                 default = nil)
  if valid_606341 != nil:
    section.add "nextToken", valid_606341
  var valid_606342 = query.getOrDefault("maxResults")
  valid_606342 = validateParameter(valid_606342, JString, required = false,
                                 default = nil)
  if valid_606342 != nil:
    section.add "maxResults", valid_606342
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
  var valid_606343 = header.getOrDefault("X-Amz-Target")
  valid_606343 = validateParameter(valid_606343, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.DescribeRepositories"))
  if valid_606343 != nil:
    section.add "X-Amz-Target", valid_606343
  var valid_606344 = header.getOrDefault("X-Amz-Signature")
  valid_606344 = validateParameter(valid_606344, JString, required = false,
                                 default = nil)
  if valid_606344 != nil:
    section.add "X-Amz-Signature", valid_606344
  var valid_606345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606345 = validateParameter(valid_606345, JString, required = false,
                                 default = nil)
  if valid_606345 != nil:
    section.add "X-Amz-Content-Sha256", valid_606345
  var valid_606346 = header.getOrDefault("X-Amz-Date")
  valid_606346 = validateParameter(valid_606346, JString, required = false,
                                 default = nil)
  if valid_606346 != nil:
    section.add "X-Amz-Date", valid_606346
  var valid_606347 = header.getOrDefault("X-Amz-Credential")
  valid_606347 = validateParameter(valid_606347, JString, required = false,
                                 default = nil)
  if valid_606347 != nil:
    section.add "X-Amz-Credential", valid_606347
  var valid_606348 = header.getOrDefault("X-Amz-Security-Token")
  valid_606348 = validateParameter(valid_606348, JString, required = false,
                                 default = nil)
  if valid_606348 != nil:
    section.add "X-Amz-Security-Token", valid_606348
  var valid_606349 = header.getOrDefault("X-Amz-Algorithm")
  valid_606349 = validateParameter(valid_606349, JString, required = false,
                                 default = nil)
  if valid_606349 != nil:
    section.add "X-Amz-Algorithm", valid_606349
  var valid_606350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606350 = validateParameter(valid_606350, JString, required = false,
                                 default = nil)
  if valid_606350 != nil:
    section.add "X-Amz-SignedHeaders", valid_606350
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606352: Call_DescribeRepositories_606338; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes image repositories in a registry.
  ## 
  let valid = call_606352.validator(path, query, header, formData, body)
  let scheme = call_606352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606352.url(scheme.get, call_606352.host, call_606352.base,
                         call_606352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606352, url, valid)

proc call*(call_606353: Call_DescribeRepositories_606338; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## describeRepositories
  ## Describes image repositories in a registry.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606354 = newJObject()
  var body_606355 = newJObject()
  add(query_606354, "nextToken", newJString(nextToken))
  if body != nil:
    body_606355 = body
  add(query_606354, "maxResults", newJString(maxResults))
  result = call_606353.call(nil, query_606354, nil, nil, body_606355)

var describeRepositories* = Call_DescribeRepositories_606338(
    name: "describeRepositories", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.DescribeRepositories",
    validator: validate_DescribeRepositories_606339, base: "/",
    url: url_DescribeRepositories_606340, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizationToken_606356 = ref object of OpenApiRestCall_605589
proc url_GetAuthorizationToken_606358(protocol: Scheme; host: string; base: string;
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

proc validate_GetAuthorizationToken_606357(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves a token that is valid for a specified registry for 12 hours. This command allows you to use the <code>docker</code> CLI to push and pull images with Amazon ECR. If you do not specify a registry, the default registry is assumed.</p> <p>The <code>authorizationToken</code> returned for each registry specified is a base64 encoded string that can be decoded and used in a <code>docker login</code> command to authenticate to a registry. The AWS CLI offers an <code>aws ecr get-login</code> command that simplifies the login process.</p>
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
  var valid_606359 = header.getOrDefault("X-Amz-Target")
  valid_606359 = validateParameter(valid_606359, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.GetAuthorizationToken"))
  if valid_606359 != nil:
    section.add "X-Amz-Target", valid_606359
  var valid_606360 = header.getOrDefault("X-Amz-Signature")
  valid_606360 = validateParameter(valid_606360, JString, required = false,
                                 default = nil)
  if valid_606360 != nil:
    section.add "X-Amz-Signature", valid_606360
  var valid_606361 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606361 = validateParameter(valid_606361, JString, required = false,
                                 default = nil)
  if valid_606361 != nil:
    section.add "X-Amz-Content-Sha256", valid_606361
  var valid_606362 = header.getOrDefault("X-Amz-Date")
  valid_606362 = validateParameter(valid_606362, JString, required = false,
                                 default = nil)
  if valid_606362 != nil:
    section.add "X-Amz-Date", valid_606362
  var valid_606363 = header.getOrDefault("X-Amz-Credential")
  valid_606363 = validateParameter(valid_606363, JString, required = false,
                                 default = nil)
  if valid_606363 != nil:
    section.add "X-Amz-Credential", valid_606363
  var valid_606364 = header.getOrDefault("X-Amz-Security-Token")
  valid_606364 = validateParameter(valid_606364, JString, required = false,
                                 default = nil)
  if valid_606364 != nil:
    section.add "X-Amz-Security-Token", valid_606364
  var valid_606365 = header.getOrDefault("X-Amz-Algorithm")
  valid_606365 = validateParameter(valid_606365, JString, required = false,
                                 default = nil)
  if valid_606365 != nil:
    section.add "X-Amz-Algorithm", valid_606365
  var valid_606366 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606366 = validateParameter(valid_606366, JString, required = false,
                                 default = nil)
  if valid_606366 != nil:
    section.add "X-Amz-SignedHeaders", valid_606366
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606368: Call_GetAuthorizationToken_606356; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves a token that is valid for a specified registry for 12 hours. This command allows you to use the <code>docker</code> CLI to push and pull images with Amazon ECR. If you do not specify a registry, the default registry is assumed.</p> <p>The <code>authorizationToken</code> returned for each registry specified is a base64 encoded string that can be decoded and used in a <code>docker login</code> command to authenticate to a registry. The AWS CLI offers an <code>aws ecr get-login</code> command that simplifies the login process.</p>
  ## 
  let valid = call_606368.validator(path, query, header, formData, body)
  let scheme = call_606368.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606368.url(scheme.get, call_606368.host, call_606368.base,
                         call_606368.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606368, url, valid)

proc call*(call_606369: Call_GetAuthorizationToken_606356; body: JsonNode): Recallable =
  ## getAuthorizationToken
  ## <p>Retrieves a token that is valid for a specified registry for 12 hours. This command allows you to use the <code>docker</code> CLI to push and pull images with Amazon ECR. If you do not specify a registry, the default registry is assumed.</p> <p>The <code>authorizationToken</code> returned for each registry specified is a base64 encoded string that can be decoded and used in a <code>docker login</code> command to authenticate to a registry. The AWS CLI offers an <code>aws ecr get-login</code> command that simplifies the login process.</p>
  ##   body: JObject (required)
  var body_606370 = newJObject()
  if body != nil:
    body_606370 = body
  result = call_606369.call(nil, nil, nil, nil, body_606370)

var getAuthorizationToken* = Call_GetAuthorizationToken_606356(
    name: "getAuthorizationToken", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.GetAuthorizationToken",
    validator: validate_GetAuthorizationToken_606357, base: "/",
    url: url_GetAuthorizationToken_606358, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDownloadUrlForLayer_606371 = ref object of OpenApiRestCall_605589
proc url_GetDownloadUrlForLayer_606373(protocol: Scheme; host: string; base: string;
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

proc validate_GetDownloadUrlForLayer_606372(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves the pre-signed Amazon S3 download URL corresponding to an image layer. You can only get URLs for image layers that are referenced in an image.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
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
  var valid_606374 = header.getOrDefault("X-Amz-Target")
  valid_606374 = validateParameter(valid_606374, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.GetDownloadUrlForLayer"))
  if valid_606374 != nil:
    section.add "X-Amz-Target", valid_606374
  var valid_606375 = header.getOrDefault("X-Amz-Signature")
  valid_606375 = validateParameter(valid_606375, JString, required = false,
                                 default = nil)
  if valid_606375 != nil:
    section.add "X-Amz-Signature", valid_606375
  var valid_606376 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606376 = validateParameter(valid_606376, JString, required = false,
                                 default = nil)
  if valid_606376 != nil:
    section.add "X-Amz-Content-Sha256", valid_606376
  var valid_606377 = header.getOrDefault("X-Amz-Date")
  valid_606377 = validateParameter(valid_606377, JString, required = false,
                                 default = nil)
  if valid_606377 != nil:
    section.add "X-Amz-Date", valid_606377
  var valid_606378 = header.getOrDefault("X-Amz-Credential")
  valid_606378 = validateParameter(valid_606378, JString, required = false,
                                 default = nil)
  if valid_606378 != nil:
    section.add "X-Amz-Credential", valid_606378
  var valid_606379 = header.getOrDefault("X-Amz-Security-Token")
  valid_606379 = validateParameter(valid_606379, JString, required = false,
                                 default = nil)
  if valid_606379 != nil:
    section.add "X-Amz-Security-Token", valid_606379
  var valid_606380 = header.getOrDefault("X-Amz-Algorithm")
  valid_606380 = validateParameter(valid_606380, JString, required = false,
                                 default = nil)
  if valid_606380 != nil:
    section.add "X-Amz-Algorithm", valid_606380
  var valid_606381 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606381 = validateParameter(valid_606381, JString, required = false,
                                 default = nil)
  if valid_606381 != nil:
    section.add "X-Amz-SignedHeaders", valid_606381
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606383: Call_GetDownloadUrlForLayer_606371; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the pre-signed Amazon S3 download URL corresponding to an image layer. You can only get URLs for image layers that are referenced in an image.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ## 
  let valid = call_606383.validator(path, query, header, formData, body)
  let scheme = call_606383.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606383.url(scheme.get, call_606383.host, call_606383.base,
                         call_606383.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606383, url, valid)

proc call*(call_606384: Call_GetDownloadUrlForLayer_606371; body: JsonNode): Recallable =
  ## getDownloadUrlForLayer
  ## <p>Retrieves the pre-signed Amazon S3 download URL corresponding to an image layer. You can only get URLs for image layers that are referenced in an image.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ##   body: JObject (required)
  var body_606385 = newJObject()
  if body != nil:
    body_606385 = body
  result = call_606384.call(nil, nil, nil, nil, body_606385)

var getDownloadUrlForLayer* = Call_GetDownloadUrlForLayer_606371(
    name: "getDownloadUrlForLayer", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.GetDownloadUrlForLayer",
    validator: validate_GetDownloadUrlForLayer_606372, base: "/",
    url: url_GetDownloadUrlForLayer_606373, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLifecyclePolicy_606386 = ref object of OpenApiRestCall_605589
proc url_GetLifecyclePolicy_606388(protocol: Scheme; host: string; base: string;
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

proc validate_GetLifecyclePolicy_606387(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Retrieves the specified lifecycle policy.
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
  var valid_606389 = header.getOrDefault("X-Amz-Target")
  valid_606389 = validateParameter(valid_606389, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.GetLifecyclePolicy"))
  if valid_606389 != nil:
    section.add "X-Amz-Target", valid_606389
  var valid_606390 = header.getOrDefault("X-Amz-Signature")
  valid_606390 = validateParameter(valid_606390, JString, required = false,
                                 default = nil)
  if valid_606390 != nil:
    section.add "X-Amz-Signature", valid_606390
  var valid_606391 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606391 = validateParameter(valid_606391, JString, required = false,
                                 default = nil)
  if valid_606391 != nil:
    section.add "X-Amz-Content-Sha256", valid_606391
  var valid_606392 = header.getOrDefault("X-Amz-Date")
  valid_606392 = validateParameter(valid_606392, JString, required = false,
                                 default = nil)
  if valid_606392 != nil:
    section.add "X-Amz-Date", valid_606392
  var valid_606393 = header.getOrDefault("X-Amz-Credential")
  valid_606393 = validateParameter(valid_606393, JString, required = false,
                                 default = nil)
  if valid_606393 != nil:
    section.add "X-Amz-Credential", valid_606393
  var valid_606394 = header.getOrDefault("X-Amz-Security-Token")
  valid_606394 = validateParameter(valid_606394, JString, required = false,
                                 default = nil)
  if valid_606394 != nil:
    section.add "X-Amz-Security-Token", valid_606394
  var valid_606395 = header.getOrDefault("X-Amz-Algorithm")
  valid_606395 = validateParameter(valid_606395, JString, required = false,
                                 default = nil)
  if valid_606395 != nil:
    section.add "X-Amz-Algorithm", valid_606395
  var valid_606396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606396 = validateParameter(valid_606396, JString, required = false,
                                 default = nil)
  if valid_606396 != nil:
    section.add "X-Amz-SignedHeaders", valid_606396
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606398: Call_GetLifecyclePolicy_606386; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the specified lifecycle policy.
  ## 
  let valid = call_606398.validator(path, query, header, formData, body)
  let scheme = call_606398.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606398.url(scheme.get, call_606398.host, call_606398.base,
                         call_606398.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606398, url, valid)

proc call*(call_606399: Call_GetLifecyclePolicy_606386; body: JsonNode): Recallable =
  ## getLifecyclePolicy
  ## Retrieves the specified lifecycle policy.
  ##   body: JObject (required)
  var body_606400 = newJObject()
  if body != nil:
    body_606400 = body
  result = call_606399.call(nil, nil, nil, nil, body_606400)

var getLifecyclePolicy* = Call_GetLifecyclePolicy_606386(
    name: "getLifecyclePolicy", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.GetLifecyclePolicy",
    validator: validate_GetLifecyclePolicy_606387, base: "/",
    url: url_GetLifecyclePolicy_606388, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLifecyclePolicyPreview_606401 = ref object of OpenApiRestCall_605589
proc url_GetLifecyclePolicyPreview_606403(protocol: Scheme; host: string;
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

proc validate_GetLifecyclePolicyPreview_606402(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the results of the specified lifecycle policy preview request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_606404 = query.getOrDefault("nextToken")
  valid_606404 = validateParameter(valid_606404, JString, required = false,
                                 default = nil)
  if valid_606404 != nil:
    section.add "nextToken", valid_606404
  var valid_606405 = query.getOrDefault("maxResults")
  valid_606405 = validateParameter(valid_606405, JString, required = false,
                                 default = nil)
  if valid_606405 != nil:
    section.add "maxResults", valid_606405
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
  var valid_606406 = header.getOrDefault("X-Amz-Target")
  valid_606406 = validateParameter(valid_606406, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.GetLifecyclePolicyPreview"))
  if valid_606406 != nil:
    section.add "X-Amz-Target", valid_606406
  var valid_606407 = header.getOrDefault("X-Amz-Signature")
  valid_606407 = validateParameter(valid_606407, JString, required = false,
                                 default = nil)
  if valid_606407 != nil:
    section.add "X-Amz-Signature", valid_606407
  var valid_606408 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606408 = validateParameter(valid_606408, JString, required = false,
                                 default = nil)
  if valid_606408 != nil:
    section.add "X-Amz-Content-Sha256", valid_606408
  var valid_606409 = header.getOrDefault("X-Amz-Date")
  valid_606409 = validateParameter(valid_606409, JString, required = false,
                                 default = nil)
  if valid_606409 != nil:
    section.add "X-Amz-Date", valid_606409
  var valid_606410 = header.getOrDefault("X-Amz-Credential")
  valid_606410 = validateParameter(valid_606410, JString, required = false,
                                 default = nil)
  if valid_606410 != nil:
    section.add "X-Amz-Credential", valid_606410
  var valid_606411 = header.getOrDefault("X-Amz-Security-Token")
  valid_606411 = validateParameter(valid_606411, JString, required = false,
                                 default = nil)
  if valid_606411 != nil:
    section.add "X-Amz-Security-Token", valid_606411
  var valid_606412 = header.getOrDefault("X-Amz-Algorithm")
  valid_606412 = validateParameter(valid_606412, JString, required = false,
                                 default = nil)
  if valid_606412 != nil:
    section.add "X-Amz-Algorithm", valid_606412
  var valid_606413 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606413 = validateParameter(valid_606413, JString, required = false,
                                 default = nil)
  if valid_606413 != nil:
    section.add "X-Amz-SignedHeaders", valid_606413
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606415: Call_GetLifecyclePolicyPreview_606401; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the results of the specified lifecycle policy preview request.
  ## 
  let valid = call_606415.validator(path, query, header, formData, body)
  let scheme = call_606415.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606415.url(scheme.get, call_606415.host, call_606415.base,
                         call_606415.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606415, url, valid)

proc call*(call_606416: Call_GetLifecyclePolicyPreview_606401; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getLifecyclePolicyPreview
  ## Retrieves the results of the specified lifecycle policy preview request.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606417 = newJObject()
  var body_606418 = newJObject()
  add(query_606417, "nextToken", newJString(nextToken))
  if body != nil:
    body_606418 = body
  add(query_606417, "maxResults", newJString(maxResults))
  result = call_606416.call(nil, query_606417, nil, nil, body_606418)

var getLifecyclePolicyPreview* = Call_GetLifecyclePolicyPreview_606401(
    name: "getLifecyclePolicyPreview", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.GetLifecyclePolicyPreview",
    validator: validate_GetLifecyclePolicyPreview_606402, base: "/",
    url: url_GetLifecyclePolicyPreview_606403,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRepositoryPolicy_606419 = ref object of OpenApiRestCall_605589
proc url_GetRepositoryPolicy_606421(protocol: Scheme; host: string; base: string;
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

proc validate_GetRepositoryPolicy_606420(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Retrieves the repository policy for a specified repository.
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
  var valid_606422 = header.getOrDefault("X-Amz-Target")
  valid_606422 = validateParameter(valid_606422, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.GetRepositoryPolicy"))
  if valid_606422 != nil:
    section.add "X-Amz-Target", valid_606422
  var valid_606423 = header.getOrDefault("X-Amz-Signature")
  valid_606423 = validateParameter(valid_606423, JString, required = false,
                                 default = nil)
  if valid_606423 != nil:
    section.add "X-Amz-Signature", valid_606423
  var valid_606424 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606424 = validateParameter(valid_606424, JString, required = false,
                                 default = nil)
  if valid_606424 != nil:
    section.add "X-Amz-Content-Sha256", valid_606424
  var valid_606425 = header.getOrDefault("X-Amz-Date")
  valid_606425 = validateParameter(valid_606425, JString, required = false,
                                 default = nil)
  if valid_606425 != nil:
    section.add "X-Amz-Date", valid_606425
  var valid_606426 = header.getOrDefault("X-Amz-Credential")
  valid_606426 = validateParameter(valid_606426, JString, required = false,
                                 default = nil)
  if valid_606426 != nil:
    section.add "X-Amz-Credential", valid_606426
  var valid_606427 = header.getOrDefault("X-Amz-Security-Token")
  valid_606427 = validateParameter(valid_606427, JString, required = false,
                                 default = nil)
  if valid_606427 != nil:
    section.add "X-Amz-Security-Token", valid_606427
  var valid_606428 = header.getOrDefault("X-Amz-Algorithm")
  valid_606428 = validateParameter(valid_606428, JString, required = false,
                                 default = nil)
  if valid_606428 != nil:
    section.add "X-Amz-Algorithm", valid_606428
  var valid_606429 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606429 = validateParameter(valid_606429, JString, required = false,
                                 default = nil)
  if valid_606429 != nil:
    section.add "X-Amz-SignedHeaders", valid_606429
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606431: Call_GetRepositoryPolicy_606419; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the repository policy for a specified repository.
  ## 
  let valid = call_606431.validator(path, query, header, formData, body)
  let scheme = call_606431.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606431.url(scheme.get, call_606431.host, call_606431.base,
                         call_606431.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606431, url, valid)

proc call*(call_606432: Call_GetRepositoryPolicy_606419; body: JsonNode): Recallable =
  ## getRepositoryPolicy
  ## Retrieves the repository policy for a specified repository.
  ##   body: JObject (required)
  var body_606433 = newJObject()
  if body != nil:
    body_606433 = body
  result = call_606432.call(nil, nil, nil, nil, body_606433)

var getRepositoryPolicy* = Call_GetRepositoryPolicy_606419(
    name: "getRepositoryPolicy", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.GetRepositoryPolicy",
    validator: validate_GetRepositoryPolicy_606420, base: "/",
    url: url_GetRepositoryPolicy_606421, schemes: {Scheme.Https, Scheme.Http})
type
  Call_InitiateLayerUpload_606434 = ref object of OpenApiRestCall_605589
proc url_InitiateLayerUpload_606436(protocol: Scheme; host: string; base: string;
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

proc validate_InitiateLayerUpload_606435(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Notify Amazon ECR that you intend to upload an image layer.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
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
  var valid_606437 = header.getOrDefault("X-Amz-Target")
  valid_606437 = validateParameter(valid_606437, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.InitiateLayerUpload"))
  if valid_606437 != nil:
    section.add "X-Amz-Target", valid_606437
  var valid_606438 = header.getOrDefault("X-Amz-Signature")
  valid_606438 = validateParameter(valid_606438, JString, required = false,
                                 default = nil)
  if valid_606438 != nil:
    section.add "X-Amz-Signature", valid_606438
  var valid_606439 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606439 = validateParameter(valid_606439, JString, required = false,
                                 default = nil)
  if valid_606439 != nil:
    section.add "X-Amz-Content-Sha256", valid_606439
  var valid_606440 = header.getOrDefault("X-Amz-Date")
  valid_606440 = validateParameter(valid_606440, JString, required = false,
                                 default = nil)
  if valid_606440 != nil:
    section.add "X-Amz-Date", valid_606440
  var valid_606441 = header.getOrDefault("X-Amz-Credential")
  valid_606441 = validateParameter(valid_606441, JString, required = false,
                                 default = nil)
  if valid_606441 != nil:
    section.add "X-Amz-Credential", valid_606441
  var valid_606442 = header.getOrDefault("X-Amz-Security-Token")
  valid_606442 = validateParameter(valid_606442, JString, required = false,
                                 default = nil)
  if valid_606442 != nil:
    section.add "X-Amz-Security-Token", valid_606442
  var valid_606443 = header.getOrDefault("X-Amz-Algorithm")
  valid_606443 = validateParameter(valid_606443, JString, required = false,
                                 default = nil)
  if valid_606443 != nil:
    section.add "X-Amz-Algorithm", valid_606443
  var valid_606444 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606444 = validateParameter(valid_606444, JString, required = false,
                                 default = nil)
  if valid_606444 != nil:
    section.add "X-Amz-SignedHeaders", valid_606444
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606446: Call_InitiateLayerUpload_606434; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Notify Amazon ECR that you intend to upload an image layer.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ## 
  let valid = call_606446.validator(path, query, header, formData, body)
  let scheme = call_606446.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606446.url(scheme.get, call_606446.host, call_606446.base,
                         call_606446.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606446, url, valid)

proc call*(call_606447: Call_InitiateLayerUpload_606434; body: JsonNode): Recallable =
  ## initiateLayerUpload
  ## <p>Notify Amazon ECR that you intend to upload an image layer.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ##   body: JObject (required)
  var body_606448 = newJObject()
  if body != nil:
    body_606448 = body
  result = call_606447.call(nil, nil, nil, nil, body_606448)

var initiateLayerUpload* = Call_InitiateLayerUpload_606434(
    name: "initiateLayerUpload", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.InitiateLayerUpload",
    validator: validate_InitiateLayerUpload_606435, base: "/",
    url: url_InitiateLayerUpload_606436, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListImages_606449 = ref object of OpenApiRestCall_605589
proc url_ListImages_606451(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListImages_606450(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists all the image IDs for a given repository.</p> <p>You can filter images based on whether or not they are tagged by setting the <code>tagStatus</code> parameter to <code>TAGGED</code> or <code>UNTAGGED</code>. For example, you can filter your results to return only <code>UNTAGGED</code> images and then pipe that result to a <a>BatchDeleteImage</a> operation to delete them. Or, you can filter your results to return only <code>TAGGED</code> images to list all of the tags in your repository.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_606452 = query.getOrDefault("nextToken")
  valid_606452 = validateParameter(valid_606452, JString, required = false,
                                 default = nil)
  if valid_606452 != nil:
    section.add "nextToken", valid_606452
  var valid_606453 = query.getOrDefault("maxResults")
  valid_606453 = validateParameter(valid_606453, JString, required = false,
                                 default = nil)
  if valid_606453 != nil:
    section.add "maxResults", valid_606453
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
  var valid_606454 = header.getOrDefault("X-Amz-Target")
  valid_606454 = validateParameter(valid_606454, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.ListImages"))
  if valid_606454 != nil:
    section.add "X-Amz-Target", valid_606454
  var valid_606455 = header.getOrDefault("X-Amz-Signature")
  valid_606455 = validateParameter(valid_606455, JString, required = false,
                                 default = nil)
  if valid_606455 != nil:
    section.add "X-Amz-Signature", valid_606455
  var valid_606456 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606456 = validateParameter(valid_606456, JString, required = false,
                                 default = nil)
  if valid_606456 != nil:
    section.add "X-Amz-Content-Sha256", valid_606456
  var valid_606457 = header.getOrDefault("X-Amz-Date")
  valid_606457 = validateParameter(valid_606457, JString, required = false,
                                 default = nil)
  if valid_606457 != nil:
    section.add "X-Amz-Date", valid_606457
  var valid_606458 = header.getOrDefault("X-Amz-Credential")
  valid_606458 = validateParameter(valid_606458, JString, required = false,
                                 default = nil)
  if valid_606458 != nil:
    section.add "X-Amz-Credential", valid_606458
  var valid_606459 = header.getOrDefault("X-Amz-Security-Token")
  valid_606459 = validateParameter(valid_606459, JString, required = false,
                                 default = nil)
  if valid_606459 != nil:
    section.add "X-Amz-Security-Token", valid_606459
  var valid_606460 = header.getOrDefault("X-Amz-Algorithm")
  valid_606460 = validateParameter(valid_606460, JString, required = false,
                                 default = nil)
  if valid_606460 != nil:
    section.add "X-Amz-Algorithm", valid_606460
  var valid_606461 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606461 = validateParameter(valid_606461, JString, required = false,
                                 default = nil)
  if valid_606461 != nil:
    section.add "X-Amz-SignedHeaders", valid_606461
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606463: Call_ListImages_606449; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists all the image IDs for a given repository.</p> <p>You can filter images based on whether or not they are tagged by setting the <code>tagStatus</code> parameter to <code>TAGGED</code> or <code>UNTAGGED</code>. For example, you can filter your results to return only <code>UNTAGGED</code> images and then pipe that result to a <a>BatchDeleteImage</a> operation to delete them. Or, you can filter your results to return only <code>TAGGED</code> images to list all of the tags in your repository.</p>
  ## 
  let valid = call_606463.validator(path, query, header, formData, body)
  let scheme = call_606463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606463.url(scheme.get, call_606463.host, call_606463.base,
                         call_606463.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606463, url, valid)

proc call*(call_606464: Call_ListImages_606449; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listImages
  ## <p>Lists all the image IDs for a given repository.</p> <p>You can filter images based on whether or not they are tagged by setting the <code>tagStatus</code> parameter to <code>TAGGED</code> or <code>UNTAGGED</code>. For example, you can filter your results to return only <code>UNTAGGED</code> images and then pipe that result to a <a>BatchDeleteImage</a> operation to delete them. Or, you can filter your results to return only <code>TAGGED</code> images to list all of the tags in your repository.</p>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606465 = newJObject()
  var body_606466 = newJObject()
  add(query_606465, "nextToken", newJString(nextToken))
  if body != nil:
    body_606466 = body
  add(query_606465, "maxResults", newJString(maxResults))
  result = call_606464.call(nil, query_606465, nil, nil, body_606466)

var listImages* = Call_ListImages_606449(name: "listImages",
                                      meth: HttpMethod.HttpPost,
                                      host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.ListImages",
                                      validator: validate_ListImages_606450,
                                      base: "/", url: url_ListImages_606451,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_606467 = ref object of OpenApiRestCall_605589
proc url_ListTagsForResource_606469(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_606468(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## List the tags for an Amazon ECR resource.
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
  var valid_606470 = header.getOrDefault("X-Amz-Target")
  valid_606470 = validateParameter(valid_606470, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.ListTagsForResource"))
  if valid_606470 != nil:
    section.add "X-Amz-Target", valid_606470
  var valid_606471 = header.getOrDefault("X-Amz-Signature")
  valid_606471 = validateParameter(valid_606471, JString, required = false,
                                 default = nil)
  if valid_606471 != nil:
    section.add "X-Amz-Signature", valid_606471
  var valid_606472 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606472 = validateParameter(valid_606472, JString, required = false,
                                 default = nil)
  if valid_606472 != nil:
    section.add "X-Amz-Content-Sha256", valid_606472
  var valid_606473 = header.getOrDefault("X-Amz-Date")
  valid_606473 = validateParameter(valid_606473, JString, required = false,
                                 default = nil)
  if valid_606473 != nil:
    section.add "X-Amz-Date", valid_606473
  var valid_606474 = header.getOrDefault("X-Amz-Credential")
  valid_606474 = validateParameter(valid_606474, JString, required = false,
                                 default = nil)
  if valid_606474 != nil:
    section.add "X-Amz-Credential", valid_606474
  var valid_606475 = header.getOrDefault("X-Amz-Security-Token")
  valid_606475 = validateParameter(valid_606475, JString, required = false,
                                 default = nil)
  if valid_606475 != nil:
    section.add "X-Amz-Security-Token", valid_606475
  var valid_606476 = header.getOrDefault("X-Amz-Algorithm")
  valid_606476 = validateParameter(valid_606476, JString, required = false,
                                 default = nil)
  if valid_606476 != nil:
    section.add "X-Amz-Algorithm", valid_606476
  var valid_606477 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606477 = validateParameter(valid_606477, JString, required = false,
                                 default = nil)
  if valid_606477 != nil:
    section.add "X-Amz-SignedHeaders", valid_606477
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606479: Call_ListTagsForResource_606467; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the tags for an Amazon ECR resource.
  ## 
  let valid = call_606479.validator(path, query, header, formData, body)
  let scheme = call_606479.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606479.url(scheme.get, call_606479.host, call_606479.base,
                         call_606479.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606479, url, valid)

proc call*(call_606480: Call_ListTagsForResource_606467; body: JsonNode): Recallable =
  ## listTagsForResource
  ## List the tags for an Amazon ECR resource.
  ##   body: JObject (required)
  var body_606481 = newJObject()
  if body != nil:
    body_606481 = body
  result = call_606480.call(nil, nil, nil, nil, body_606481)

var listTagsForResource* = Call_ListTagsForResource_606467(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.ListTagsForResource",
    validator: validate_ListTagsForResource_606468, base: "/",
    url: url_ListTagsForResource_606469, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutImage_606482 = ref object of OpenApiRestCall_605589
proc url_PutImage_606484(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_PutImage_606483(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates or updates the image manifest and tags associated with an image.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
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
  var valid_606485 = header.getOrDefault("X-Amz-Target")
  valid_606485 = validateParameter(valid_606485, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.PutImage"))
  if valid_606485 != nil:
    section.add "X-Amz-Target", valid_606485
  var valid_606486 = header.getOrDefault("X-Amz-Signature")
  valid_606486 = validateParameter(valid_606486, JString, required = false,
                                 default = nil)
  if valid_606486 != nil:
    section.add "X-Amz-Signature", valid_606486
  var valid_606487 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606487 = validateParameter(valid_606487, JString, required = false,
                                 default = nil)
  if valid_606487 != nil:
    section.add "X-Amz-Content-Sha256", valid_606487
  var valid_606488 = header.getOrDefault("X-Amz-Date")
  valid_606488 = validateParameter(valid_606488, JString, required = false,
                                 default = nil)
  if valid_606488 != nil:
    section.add "X-Amz-Date", valid_606488
  var valid_606489 = header.getOrDefault("X-Amz-Credential")
  valid_606489 = validateParameter(valid_606489, JString, required = false,
                                 default = nil)
  if valid_606489 != nil:
    section.add "X-Amz-Credential", valid_606489
  var valid_606490 = header.getOrDefault("X-Amz-Security-Token")
  valid_606490 = validateParameter(valid_606490, JString, required = false,
                                 default = nil)
  if valid_606490 != nil:
    section.add "X-Amz-Security-Token", valid_606490
  var valid_606491 = header.getOrDefault("X-Amz-Algorithm")
  valid_606491 = validateParameter(valid_606491, JString, required = false,
                                 default = nil)
  if valid_606491 != nil:
    section.add "X-Amz-Algorithm", valid_606491
  var valid_606492 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606492 = validateParameter(valid_606492, JString, required = false,
                                 default = nil)
  if valid_606492 != nil:
    section.add "X-Amz-SignedHeaders", valid_606492
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606494: Call_PutImage_606482; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates or updates the image manifest and tags associated with an image.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ## 
  let valid = call_606494.validator(path, query, header, formData, body)
  let scheme = call_606494.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606494.url(scheme.get, call_606494.host, call_606494.base,
                         call_606494.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606494, url, valid)

proc call*(call_606495: Call_PutImage_606482; body: JsonNode): Recallable =
  ## putImage
  ## <p>Creates or updates the image manifest and tags associated with an image.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ##   body: JObject (required)
  var body_606496 = newJObject()
  if body != nil:
    body_606496 = body
  result = call_606495.call(nil, nil, nil, nil, body_606496)

var putImage* = Call_PutImage_606482(name: "putImage", meth: HttpMethod.HttpPost,
                                  host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.PutImage",
                                  validator: validate_PutImage_606483, base: "/",
                                  url: url_PutImage_606484,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutImageScanningConfiguration_606497 = ref object of OpenApiRestCall_605589
proc url_PutImageScanningConfiguration_606499(protocol: Scheme; host: string;
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

proc validate_PutImageScanningConfiguration_606498(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the image scanning configuration for a repository.
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
  var valid_606500 = header.getOrDefault("X-Amz-Target")
  valid_606500 = validateParameter(valid_606500, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.PutImageScanningConfiguration"))
  if valid_606500 != nil:
    section.add "X-Amz-Target", valid_606500
  var valid_606501 = header.getOrDefault("X-Amz-Signature")
  valid_606501 = validateParameter(valid_606501, JString, required = false,
                                 default = nil)
  if valid_606501 != nil:
    section.add "X-Amz-Signature", valid_606501
  var valid_606502 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606502 = validateParameter(valid_606502, JString, required = false,
                                 default = nil)
  if valid_606502 != nil:
    section.add "X-Amz-Content-Sha256", valid_606502
  var valid_606503 = header.getOrDefault("X-Amz-Date")
  valid_606503 = validateParameter(valid_606503, JString, required = false,
                                 default = nil)
  if valid_606503 != nil:
    section.add "X-Amz-Date", valid_606503
  var valid_606504 = header.getOrDefault("X-Amz-Credential")
  valid_606504 = validateParameter(valid_606504, JString, required = false,
                                 default = nil)
  if valid_606504 != nil:
    section.add "X-Amz-Credential", valid_606504
  var valid_606505 = header.getOrDefault("X-Amz-Security-Token")
  valid_606505 = validateParameter(valid_606505, JString, required = false,
                                 default = nil)
  if valid_606505 != nil:
    section.add "X-Amz-Security-Token", valid_606505
  var valid_606506 = header.getOrDefault("X-Amz-Algorithm")
  valid_606506 = validateParameter(valid_606506, JString, required = false,
                                 default = nil)
  if valid_606506 != nil:
    section.add "X-Amz-Algorithm", valid_606506
  var valid_606507 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606507 = validateParameter(valid_606507, JString, required = false,
                                 default = nil)
  if valid_606507 != nil:
    section.add "X-Amz-SignedHeaders", valid_606507
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606509: Call_PutImageScanningConfiguration_606497; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the image scanning configuration for a repository.
  ## 
  let valid = call_606509.validator(path, query, header, formData, body)
  let scheme = call_606509.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606509.url(scheme.get, call_606509.host, call_606509.base,
                         call_606509.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606509, url, valid)

proc call*(call_606510: Call_PutImageScanningConfiguration_606497; body: JsonNode): Recallable =
  ## putImageScanningConfiguration
  ## Updates the image scanning configuration for a repository.
  ##   body: JObject (required)
  var body_606511 = newJObject()
  if body != nil:
    body_606511 = body
  result = call_606510.call(nil, nil, nil, nil, body_606511)

var putImageScanningConfiguration* = Call_PutImageScanningConfiguration_606497(
    name: "putImageScanningConfiguration", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.PutImageScanningConfiguration",
    validator: validate_PutImageScanningConfiguration_606498, base: "/",
    url: url_PutImageScanningConfiguration_606499,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutImageTagMutability_606512 = ref object of OpenApiRestCall_605589
proc url_PutImageTagMutability_606514(protocol: Scheme; host: string; base: string;
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

proc validate_PutImageTagMutability_606513(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the image tag mutability settings for a repository. When a repository is configured with tag immutability, all image tags within the repository will be prevented them from being overwritten. For more information, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/image-tag-mutability.html">Image Tag Mutability</a> in the <i>Amazon Elastic Container Registry User Guide</i>.
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
  var valid_606515 = header.getOrDefault("X-Amz-Target")
  valid_606515 = validateParameter(valid_606515, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.PutImageTagMutability"))
  if valid_606515 != nil:
    section.add "X-Amz-Target", valid_606515
  var valid_606516 = header.getOrDefault("X-Amz-Signature")
  valid_606516 = validateParameter(valid_606516, JString, required = false,
                                 default = nil)
  if valid_606516 != nil:
    section.add "X-Amz-Signature", valid_606516
  var valid_606517 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606517 = validateParameter(valid_606517, JString, required = false,
                                 default = nil)
  if valid_606517 != nil:
    section.add "X-Amz-Content-Sha256", valid_606517
  var valid_606518 = header.getOrDefault("X-Amz-Date")
  valid_606518 = validateParameter(valid_606518, JString, required = false,
                                 default = nil)
  if valid_606518 != nil:
    section.add "X-Amz-Date", valid_606518
  var valid_606519 = header.getOrDefault("X-Amz-Credential")
  valid_606519 = validateParameter(valid_606519, JString, required = false,
                                 default = nil)
  if valid_606519 != nil:
    section.add "X-Amz-Credential", valid_606519
  var valid_606520 = header.getOrDefault("X-Amz-Security-Token")
  valid_606520 = validateParameter(valid_606520, JString, required = false,
                                 default = nil)
  if valid_606520 != nil:
    section.add "X-Amz-Security-Token", valid_606520
  var valid_606521 = header.getOrDefault("X-Amz-Algorithm")
  valid_606521 = validateParameter(valid_606521, JString, required = false,
                                 default = nil)
  if valid_606521 != nil:
    section.add "X-Amz-Algorithm", valid_606521
  var valid_606522 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606522 = validateParameter(valid_606522, JString, required = false,
                                 default = nil)
  if valid_606522 != nil:
    section.add "X-Amz-SignedHeaders", valid_606522
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606524: Call_PutImageTagMutability_606512; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the image tag mutability settings for a repository. When a repository is configured with tag immutability, all image tags within the repository will be prevented them from being overwritten. For more information, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/image-tag-mutability.html">Image Tag Mutability</a> in the <i>Amazon Elastic Container Registry User Guide</i>.
  ## 
  let valid = call_606524.validator(path, query, header, formData, body)
  let scheme = call_606524.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606524.url(scheme.get, call_606524.host, call_606524.base,
                         call_606524.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606524, url, valid)

proc call*(call_606525: Call_PutImageTagMutability_606512; body: JsonNode): Recallable =
  ## putImageTagMutability
  ## Updates the image tag mutability settings for a repository. When a repository is configured with tag immutability, all image tags within the repository will be prevented them from being overwritten. For more information, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/image-tag-mutability.html">Image Tag Mutability</a> in the <i>Amazon Elastic Container Registry User Guide</i>.
  ##   body: JObject (required)
  var body_606526 = newJObject()
  if body != nil:
    body_606526 = body
  result = call_606525.call(nil, nil, nil, nil, body_606526)

var putImageTagMutability* = Call_PutImageTagMutability_606512(
    name: "putImageTagMutability", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.PutImageTagMutability",
    validator: validate_PutImageTagMutability_606513, base: "/",
    url: url_PutImageTagMutability_606514, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutLifecyclePolicy_606527 = ref object of OpenApiRestCall_605589
proc url_PutLifecyclePolicy_606529(protocol: Scheme; host: string; base: string;
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

proc validate_PutLifecyclePolicy_606528(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Creates or updates a lifecycle policy. For information about lifecycle policy syntax, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/LifecyclePolicies.html">Lifecycle Policy Template</a>.
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
  var valid_606530 = header.getOrDefault("X-Amz-Target")
  valid_606530 = validateParameter(valid_606530, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.PutLifecyclePolicy"))
  if valid_606530 != nil:
    section.add "X-Amz-Target", valid_606530
  var valid_606531 = header.getOrDefault("X-Amz-Signature")
  valid_606531 = validateParameter(valid_606531, JString, required = false,
                                 default = nil)
  if valid_606531 != nil:
    section.add "X-Amz-Signature", valid_606531
  var valid_606532 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606532 = validateParameter(valid_606532, JString, required = false,
                                 default = nil)
  if valid_606532 != nil:
    section.add "X-Amz-Content-Sha256", valid_606532
  var valid_606533 = header.getOrDefault("X-Amz-Date")
  valid_606533 = validateParameter(valid_606533, JString, required = false,
                                 default = nil)
  if valid_606533 != nil:
    section.add "X-Amz-Date", valid_606533
  var valid_606534 = header.getOrDefault("X-Amz-Credential")
  valid_606534 = validateParameter(valid_606534, JString, required = false,
                                 default = nil)
  if valid_606534 != nil:
    section.add "X-Amz-Credential", valid_606534
  var valid_606535 = header.getOrDefault("X-Amz-Security-Token")
  valid_606535 = validateParameter(valid_606535, JString, required = false,
                                 default = nil)
  if valid_606535 != nil:
    section.add "X-Amz-Security-Token", valid_606535
  var valid_606536 = header.getOrDefault("X-Amz-Algorithm")
  valid_606536 = validateParameter(valid_606536, JString, required = false,
                                 default = nil)
  if valid_606536 != nil:
    section.add "X-Amz-Algorithm", valid_606536
  var valid_606537 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606537 = validateParameter(valid_606537, JString, required = false,
                                 default = nil)
  if valid_606537 != nil:
    section.add "X-Amz-SignedHeaders", valid_606537
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606539: Call_PutLifecyclePolicy_606527; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates or updates a lifecycle policy. For information about lifecycle policy syntax, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/LifecyclePolicies.html">Lifecycle Policy Template</a>.
  ## 
  let valid = call_606539.validator(path, query, header, formData, body)
  let scheme = call_606539.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606539.url(scheme.get, call_606539.host, call_606539.base,
                         call_606539.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606539, url, valid)

proc call*(call_606540: Call_PutLifecyclePolicy_606527; body: JsonNode): Recallable =
  ## putLifecyclePolicy
  ## Creates or updates a lifecycle policy. For information about lifecycle policy syntax, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/LifecyclePolicies.html">Lifecycle Policy Template</a>.
  ##   body: JObject (required)
  var body_606541 = newJObject()
  if body != nil:
    body_606541 = body
  result = call_606540.call(nil, nil, nil, nil, body_606541)

var putLifecyclePolicy* = Call_PutLifecyclePolicy_606527(
    name: "putLifecyclePolicy", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.PutLifecyclePolicy",
    validator: validate_PutLifecyclePolicy_606528, base: "/",
    url: url_PutLifecyclePolicy_606529, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetRepositoryPolicy_606542 = ref object of OpenApiRestCall_605589
proc url_SetRepositoryPolicy_606544(protocol: Scheme; host: string; base: string;
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

proc validate_SetRepositoryPolicy_606543(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Applies a repository policy on a specified repository to control access permissions. For more information, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/RepositoryPolicies.html">Amazon ECR Repository Policies</a> in the <i>Amazon Elastic Container Registry User Guide</i>.
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
  var valid_606545 = header.getOrDefault("X-Amz-Target")
  valid_606545 = validateParameter(valid_606545, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.SetRepositoryPolicy"))
  if valid_606545 != nil:
    section.add "X-Amz-Target", valid_606545
  var valid_606546 = header.getOrDefault("X-Amz-Signature")
  valid_606546 = validateParameter(valid_606546, JString, required = false,
                                 default = nil)
  if valid_606546 != nil:
    section.add "X-Amz-Signature", valid_606546
  var valid_606547 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606547 = validateParameter(valid_606547, JString, required = false,
                                 default = nil)
  if valid_606547 != nil:
    section.add "X-Amz-Content-Sha256", valid_606547
  var valid_606548 = header.getOrDefault("X-Amz-Date")
  valid_606548 = validateParameter(valid_606548, JString, required = false,
                                 default = nil)
  if valid_606548 != nil:
    section.add "X-Amz-Date", valid_606548
  var valid_606549 = header.getOrDefault("X-Amz-Credential")
  valid_606549 = validateParameter(valid_606549, JString, required = false,
                                 default = nil)
  if valid_606549 != nil:
    section.add "X-Amz-Credential", valid_606549
  var valid_606550 = header.getOrDefault("X-Amz-Security-Token")
  valid_606550 = validateParameter(valid_606550, JString, required = false,
                                 default = nil)
  if valid_606550 != nil:
    section.add "X-Amz-Security-Token", valid_606550
  var valid_606551 = header.getOrDefault("X-Amz-Algorithm")
  valid_606551 = validateParameter(valid_606551, JString, required = false,
                                 default = nil)
  if valid_606551 != nil:
    section.add "X-Amz-Algorithm", valid_606551
  var valid_606552 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606552 = validateParameter(valid_606552, JString, required = false,
                                 default = nil)
  if valid_606552 != nil:
    section.add "X-Amz-SignedHeaders", valid_606552
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606554: Call_SetRepositoryPolicy_606542; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Applies a repository policy on a specified repository to control access permissions. For more information, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/RepositoryPolicies.html">Amazon ECR Repository Policies</a> in the <i>Amazon Elastic Container Registry User Guide</i>.
  ## 
  let valid = call_606554.validator(path, query, header, formData, body)
  let scheme = call_606554.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606554.url(scheme.get, call_606554.host, call_606554.base,
                         call_606554.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606554, url, valid)

proc call*(call_606555: Call_SetRepositoryPolicy_606542; body: JsonNode): Recallable =
  ## setRepositoryPolicy
  ## Applies a repository policy on a specified repository to control access permissions. For more information, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/RepositoryPolicies.html">Amazon ECR Repository Policies</a> in the <i>Amazon Elastic Container Registry User Guide</i>.
  ##   body: JObject (required)
  var body_606556 = newJObject()
  if body != nil:
    body_606556 = body
  result = call_606555.call(nil, nil, nil, nil, body_606556)

var setRepositoryPolicy* = Call_SetRepositoryPolicy_606542(
    name: "setRepositoryPolicy", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.SetRepositoryPolicy",
    validator: validate_SetRepositoryPolicy_606543, base: "/",
    url: url_SetRepositoryPolicy_606544, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartImageScan_606557 = ref object of OpenApiRestCall_605589
proc url_StartImageScan_606559(protocol: Scheme; host: string; base: string;
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

proc validate_StartImageScan_606558(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Starts an image vulnerability scan. An image scan can only be started once per day on an individual image. This limit includes if an image was scanned on initial push. For more information, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/image-scanning.html">Image Scanning</a> in the <i>Amazon Elastic Container Registry User Guide</i>.
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
  var valid_606560 = header.getOrDefault("X-Amz-Target")
  valid_606560 = validateParameter(valid_606560, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.StartImageScan"))
  if valid_606560 != nil:
    section.add "X-Amz-Target", valid_606560
  var valid_606561 = header.getOrDefault("X-Amz-Signature")
  valid_606561 = validateParameter(valid_606561, JString, required = false,
                                 default = nil)
  if valid_606561 != nil:
    section.add "X-Amz-Signature", valid_606561
  var valid_606562 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606562 = validateParameter(valid_606562, JString, required = false,
                                 default = nil)
  if valid_606562 != nil:
    section.add "X-Amz-Content-Sha256", valid_606562
  var valid_606563 = header.getOrDefault("X-Amz-Date")
  valid_606563 = validateParameter(valid_606563, JString, required = false,
                                 default = nil)
  if valid_606563 != nil:
    section.add "X-Amz-Date", valid_606563
  var valid_606564 = header.getOrDefault("X-Amz-Credential")
  valid_606564 = validateParameter(valid_606564, JString, required = false,
                                 default = nil)
  if valid_606564 != nil:
    section.add "X-Amz-Credential", valid_606564
  var valid_606565 = header.getOrDefault("X-Amz-Security-Token")
  valid_606565 = validateParameter(valid_606565, JString, required = false,
                                 default = nil)
  if valid_606565 != nil:
    section.add "X-Amz-Security-Token", valid_606565
  var valid_606566 = header.getOrDefault("X-Amz-Algorithm")
  valid_606566 = validateParameter(valid_606566, JString, required = false,
                                 default = nil)
  if valid_606566 != nil:
    section.add "X-Amz-Algorithm", valid_606566
  var valid_606567 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606567 = validateParameter(valid_606567, JString, required = false,
                                 default = nil)
  if valid_606567 != nil:
    section.add "X-Amz-SignedHeaders", valid_606567
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606569: Call_StartImageScan_606557; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts an image vulnerability scan. An image scan can only be started once per day on an individual image. This limit includes if an image was scanned on initial push. For more information, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/image-scanning.html">Image Scanning</a> in the <i>Amazon Elastic Container Registry User Guide</i>.
  ## 
  let valid = call_606569.validator(path, query, header, formData, body)
  let scheme = call_606569.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606569.url(scheme.get, call_606569.host, call_606569.base,
                         call_606569.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606569, url, valid)

proc call*(call_606570: Call_StartImageScan_606557; body: JsonNode): Recallable =
  ## startImageScan
  ## Starts an image vulnerability scan. An image scan can only be started once per day on an individual image. This limit includes if an image was scanned on initial push. For more information, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/image-scanning.html">Image Scanning</a> in the <i>Amazon Elastic Container Registry User Guide</i>.
  ##   body: JObject (required)
  var body_606571 = newJObject()
  if body != nil:
    body_606571 = body
  result = call_606570.call(nil, nil, nil, nil, body_606571)

var startImageScan* = Call_StartImageScan_606557(name: "startImageScan",
    meth: HttpMethod.HttpPost, host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.StartImageScan",
    validator: validate_StartImageScan_606558, base: "/", url: url_StartImageScan_606559,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartLifecyclePolicyPreview_606572 = ref object of OpenApiRestCall_605589
proc url_StartLifecyclePolicyPreview_606574(protocol: Scheme; host: string;
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

proc validate_StartLifecyclePolicyPreview_606573(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Starts a preview of the specified lifecycle policy. This allows you to see the results before creating the lifecycle policy.
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
  var valid_606575 = header.getOrDefault("X-Amz-Target")
  valid_606575 = validateParameter(valid_606575, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.StartLifecyclePolicyPreview"))
  if valid_606575 != nil:
    section.add "X-Amz-Target", valid_606575
  var valid_606576 = header.getOrDefault("X-Amz-Signature")
  valid_606576 = validateParameter(valid_606576, JString, required = false,
                                 default = nil)
  if valid_606576 != nil:
    section.add "X-Amz-Signature", valid_606576
  var valid_606577 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606577 = validateParameter(valid_606577, JString, required = false,
                                 default = nil)
  if valid_606577 != nil:
    section.add "X-Amz-Content-Sha256", valid_606577
  var valid_606578 = header.getOrDefault("X-Amz-Date")
  valid_606578 = validateParameter(valid_606578, JString, required = false,
                                 default = nil)
  if valid_606578 != nil:
    section.add "X-Amz-Date", valid_606578
  var valid_606579 = header.getOrDefault("X-Amz-Credential")
  valid_606579 = validateParameter(valid_606579, JString, required = false,
                                 default = nil)
  if valid_606579 != nil:
    section.add "X-Amz-Credential", valid_606579
  var valid_606580 = header.getOrDefault("X-Amz-Security-Token")
  valid_606580 = validateParameter(valid_606580, JString, required = false,
                                 default = nil)
  if valid_606580 != nil:
    section.add "X-Amz-Security-Token", valid_606580
  var valid_606581 = header.getOrDefault("X-Amz-Algorithm")
  valid_606581 = validateParameter(valid_606581, JString, required = false,
                                 default = nil)
  if valid_606581 != nil:
    section.add "X-Amz-Algorithm", valid_606581
  var valid_606582 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606582 = validateParameter(valid_606582, JString, required = false,
                                 default = nil)
  if valid_606582 != nil:
    section.add "X-Amz-SignedHeaders", valid_606582
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606584: Call_StartLifecyclePolicyPreview_606572; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a preview of the specified lifecycle policy. This allows you to see the results before creating the lifecycle policy.
  ## 
  let valid = call_606584.validator(path, query, header, formData, body)
  let scheme = call_606584.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606584.url(scheme.get, call_606584.host, call_606584.base,
                         call_606584.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606584, url, valid)

proc call*(call_606585: Call_StartLifecyclePolicyPreview_606572; body: JsonNode): Recallable =
  ## startLifecyclePolicyPreview
  ## Starts a preview of the specified lifecycle policy. This allows you to see the results before creating the lifecycle policy.
  ##   body: JObject (required)
  var body_606586 = newJObject()
  if body != nil:
    body_606586 = body
  result = call_606585.call(nil, nil, nil, nil, body_606586)

var startLifecyclePolicyPreview* = Call_StartLifecyclePolicyPreview_606572(
    name: "startLifecyclePolicyPreview", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.StartLifecyclePolicyPreview",
    validator: validate_StartLifecyclePolicyPreview_606573, base: "/",
    url: url_StartLifecyclePolicyPreview_606574,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_606587 = ref object of OpenApiRestCall_605589
proc url_TagResource_606589(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_606588(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds specified tags to a resource with the specified ARN. Existing tags on a resource are not changed if they are not specified in the request parameters.
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
  var valid_606590 = header.getOrDefault("X-Amz-Target")
  valid_606590 = validateParameter(valid_606590, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.TagResource"))
  if valid_606590 != nil:
    section.add "X-Amz-Target", valid_606590
  var valid_606591 = header.getOrDefault("X-Amz-Signature")
  valid_606591 = validateParameter(valid_606591, JString, required = false,
                                 default = nil)
  if valid_606591 != nil:
    section.add "X-Amz-Signature", valid_606591
  var valid_606592 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606592 = validateParameter(valid_606592, JString, required = false,
                                 default = nil)
  if valid_606592 != nil:
    section.add "X-Amz-Content-Sha256", valid_606592
  var valid_606593 = header.getOrDefault("X-Amz-Date")
  valid_606593 = validateParameter(valid_606593, JString, required = false,
                                 default = nil)
  if valid_606593 != nil:
    section.add "X-Amz-Date", valid_606593
  var valid_606594 = header.getOrDefault("X-Amz-Credential")
  valid_606594 = validateParameter(valid_606594, JString, required = false,
                                 default = nil)
  if valid_606594 != nil:
    section.add "X-Amz-Credential", valid_606594
  var valid_606595 = header.getOrDefault("X-Amz-Security-Token")
  valid_606595 = validateParameter(valid_606595, JString, required = false,
                                 default = nil)
  if valid_606595 != nil:
    section.add "X-Amz-Security-Token", valid_606595
  var valid_606596 = header.getOrDefault("X-Amz-Algorithm")
  valid_606596 = validateParameter(valid_606596, JString, required = false,
                                 default = nil)
  if valid_606596 != nil:
    section.add "X-Amz-Algorithm", valid_606596
  var valid_606597 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606597 = validateParameter(valid_606597, JString, required = false,
                                 default = nil)
  if valid_606597 != nil:
    section.add "X-Amz-SignedHeaders", valid_606597
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606599: Call_TagResource_606587; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds specified tags to a resource with the specified ARN. Existing tags on a resource are not changed if they are not specified in the request parameters.
  ## 
  let valid = call_606599.validator(path, query, header, formData, body)
  let scheme = call_606599.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606599.url(scheme.get, call_606599.host, call_606599.base,
                         call_606599.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606599, url, valid)

proc call*(call_606600: Call_TagResource_606587; body: JsonNode): Recallable =
  ## tagResource
  ## Adds specified tags to a resource with the specified ARN. Existing tags on a resource are not changed if they are not specified in the request parameters.
  ##   body: JObject (required)
  var body_606601 = newJObject()
  if body != nil:
    body_606601 = body
  result = call_606600.call(nil, nil, nil, nil, body_606601)

var tagResource* = Call_TagResource_606587(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.TagResource",
                                        validator: validate_TagResource_606588,
                                        base: "/", url: url_TagResource_606589,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_606602 = ref object of OpenApiRestCall_605589
proc url_UntagResource_606604(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_606603(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes specified tags from a resource.
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
  var valid_606605 = header.getOrDefault("X-Amz-Target")
  valid_606605 = validateParameter(valid_606605, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.UntagResource"))
  if valid_606605 != nil:
    section.add "X-Amz-Target", valid_606605
  var valid_606606 = header.getOrDefault("X-Amz-Signature")
  valid_606606 = validateParameter(valid_606606, JString, required = false,
                                 default = nil)
  if valid_606606 != nil:
    section.add "X-Amz-Signature", valid_606606
  var valid_606607 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606607 = validateParameter(valid_606607, JString, required = false,
                                 default = nil)
  if valid_606607 != nil:
    section.add "X-Amz-Content-Sha256", valid_606607
  var valid_606608 = header.getOrDefault("X-Amz-Date")
  valid_606608 = validateParameter(valid_606608, JString, required = false,
                                 default = nil)
  if valid_606608 != nil:
    section.add "X-Amz-Date", valid_606608
  var valid_606609 = header.getOrDefault("X-Amz-Credential")
  valid_606609 = validateParameter(valid_606609, JString, required = false,
                                 default = nil)
  if valid_606609 != nil:
    section.add "X-Amz-Credential", valid_606609
  var valid_606610 = header.getOrDefault("X-Amz-Security-Token")
  valid_606610 = validateParameter(valid_606610, JString, required = false,
                                 default = nil)
  if valid_606610 != nil:
    section.add "X-Amz-Security-Token", valid_606610
  var valid_606611 = header.getOrDefault("X-Amz-Algorithm")
  valid_606611 = validateParameter(valid_606611, JString, required = false,
                                 default = nil)
  if valid_606611 != nil:
    section.add "X-Amz-Algorithm", valid_606611
  var valid_606612 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606612 = validateParameter(valid_606612, JString, required = false,
                                 default = nil)
  if valid_606612 != nil:
    section.add "X-Amz-SignedHeaders", valid_606612
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606614: Call_UntagResource_606602; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes specified tags from a resource.
  ## 
  let valid = call_606614.validator(path, query, header, formData, body)
  let scheme = call_606614.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606614.url(scheme.get, call_606614.host, call_606614.base,
                         call_606614.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606614, url, valid)

proc call*(call_606615: Call_UntagResource_606602; body: JsonNode): Recallable =
  ## untagResource
  ## Deletes specified tags from a resource.
  ##   body: JObject (required)
  var body_606616 = newJObject()
  if body != nil:
    body_606616 = body
  result = call_606615.call(nil, nil, nil, nil, body_606616)

var untagResource* = Call_UntagResource_606602(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "api.ecr.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.UntagResource",
    validator: validate_UntagResource_606603, base: "/", url: url_UntagResource_606604,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UploadLayerPart_606617 = ref object of OpenApiRestCall_605589
proc url_UploadLayerPart_606619(protocol: Scheme; host: string; base: string;
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

proc validate_UploadLayerPart_606618(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Uploads an image layer part to Amazon ECR.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
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
  var valid_606620 = header.getOrDefault("X-Amz-Target")
  valid_606620 = validateParameter(valid_606620, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.UploadLayerPart"))
  if valid_606620 != nil:
    section.add "X-Amz-Target", valid_606620
  var valid_606621 = header.getOrDefault("X-Amz-Signature")
  valid_606621 = validateParameter(valid_606621, JString, required = false,
                                 default = nil)
  if valid_606621 != nil:
    section.add "X-Amz-Signature", valid_606621
  var valid_606622 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606622 = validateParameter(valid_606622, JString, required = false,
                                 default = nil)
  if valid_606622 != nil:
    section.add "X-Amz-Content-Sha256", valid_606622
  var valid_606623 = header.getOrDefault("X-Amz-Date")
  valid_606623 = validateParameter(valid_606623, JString, required = false,
                                 default = nil)
  if valid_606623 != nil:
    section.add "X-Amz-Date", valid_606623
  var valid_606624 = header.getOrDefault("X-Amz-Credential")
  valid_606624 = validateParameter(valid_606624, JString, required = false,
                                 default = nil)
  if valid_606624 != nil:
    section.add "X-Amz-Credential", valid_606624
  var valid_606625 = header.getOrDefault("X-Amz-Security-Token")
  valid_606625 = validateParameter(valid_606625, JString, required = false,
                                 default = nil)
  if valid_606625 != nil:
    section.add "X-Amz-Security-Token", valid_606625
  var valid_606626 = header.getOrDefault("X-Amz-Algorithm")
  valid_606626 = validateParameter(valid_606626, JString, required = false,
                                 default = nil)
  if valid_606626 != nil:
    section.add "X-Amz-Algorithm", valid_606626
  var valid_606627 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606627 = validateParameter(valid_606627, JString, required = false,
                                 default = nil)
  if valid_606627 != nil:
    section.add "X-Amz-SignedHeaders", valid_606627
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606629: Call_UploadLayerPart_606617; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Uploads an image layer part to Amazon ECR.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ## 
  let valid = call_606629.validator(path, query, header, formData, body)
  let scheme = call_606629.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606629.url(scheme.get, call_606629.host, call_606629.base,
                         call_606629.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606629, url, valid)

proc call*(call_606630: Call_UploadLayerPart_606617; body: JsonNode): Recallable =
  ## uploadLayerPart
  ## <p>Uploads an image layer part to Amazon ECR.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ##   body: JObject (required)
  var body_606631 = newJObject()
  if body != nil:
    body_606631 = body
  result = call_606630.call(nil, nil, nil, nil, body_606631)

var uploadLayerPart* = Call_UploadLayerPart_606617(name: "uploadLayerPart",
    meth: HttpMethod.HttpPost, host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.UploadLayerPart",
    validator: validate_UploadLayerPart_606618, base: "/", url: url_UploadLayerPart_606619,
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
  result = newRecallable(call, url, headers, $input.getOrDefault("body"))
  result.atozSign(input.getOrDefault("query"), SHA256)
